use crate::runtime::value::Value;

#[cfg(feature = "python-bridge")]
mod imp {
    use super::Value;
    use ndarray::Array2;
    use num_complex::Complex64;
    use numpy::{PyArray1, PyArray2, PyArrayMethods, ToPyArray};
    use pyo3::IntoPyObjectExt;
    use pyo3::prelude::*;
    use pyo3::types::{PyBool, PyComplex, PyComplexMethods, PyDict, PyList, PyString, PyTuple};
    use std::collections::HashMap;
    use std::sync::{Arc, OnceLock};

    static PYTHON_PATH_INIT: OnceLock<()> = OnceLock::new();

    pub struct PythonBridge;

    impl PythonBridge {
        fn setup_python_path(py: Python<'_>) {
            PYTHON_PATH_INIT.get_or_init(|| {
                let _ = (|| -> PyResult<()> {
                    let sys = py.import("sys")?;
                    let path = sys.getattr("path")?;
                    let existing: Vec<String> = path.extract().unwrap_or_default();

                    let mut paths = vec![".".to_string(), "..".to_string(), "backend".to_string()];

                    if let Ok(cwd) = std::env::current_dir() {
                        paths.push(cwd.to_string_lossy().to_string());
                        if let Some(parent) = cwd.parent() {
                            paths.push(parent.to_string_lossy().to_string());
                        }
                    }

                    for p in paths {
                        if !existing.contains(&p) {
                            path.call_method1("insert", (0, p))?;
                        }
                    }
                    Ok(())
                })();
            });
        }

        pub fn call_plot(_x: &Value, _y: &Value) -> Result<(), String> {
            // Direct plotting from Rust is disabled to avoid segfaults with GUI backends.
            // Data is captured in Evaluator.plots and handled by the caller.
            Ok(())
        }

        pub fn call_simulate(_model: &Value, _args: Vec<Value>) -> Result<(), String> {
            // Simulation is handled at a higher level or via message passing.
            Ok(())
        }

        pub fn call_runtime_func(
            name: &str,
            args: Vec<Value>,
            nargout: usize,
        ) -> Result<Value, String> {
            Python::with_gil(|py| -> PyResult<Value> {
                Self::setup_python_path(py);

                let rt = match py.import("core.runtime") {
                    Ok(module) => module,
                    Err(_) => py.import("backend.core.runtime")?,
                };

                if let Ok(ctx) = rt.getattr("_unilab_nargout_ctx") {
                    let _ = ctx.call_method1("set", (nargout,));
                }

                let mut py_args = Vec::with_capacity(args.len());
                for arg in args {
                    py_args.push(Self::value_to_py(py, &arg)?);
                }

                let res = rt.call_method1(name, PyTuple::new(py, py_args)?)?;
                let val = Self::py_to_value(&res)?;

                if nargout > 1 {
                    if let Value::CellArray(v) = val {
                        return Ok(Value::List(v));
                    }
                }
                Ok(val)
            })
            .map_err(|e| e.to_string())
        }

        pub fn value_to_py<'py>(py: Python<'py>, val: &Value) -> PyResult<Bound<'py, PyAny>> {
            match val {
                Value::Scalar(n) => Ok(n.into_py_any(py)?.into_bound(py)),
                Value::String(s) => Ok(PyString::new(py, &**s).into_any()),
                Value::Bool(b) => Ok(b.into_py_any(py)?.into_bound(py)),
                Value::Matrix(m) => {
                    let std_m = m.as_standard_layout();
                    let py_arr = std_m.to_pyarray(py);
                    Ok(py_arr.into_any())
                }
                Value::LogicalMatrix(m) => {
                    let std_m = m.as_standard_layout();
                    let py_arr = std_m.to_pyarray(py);
                    Ok(py_arr.into_any())
                }
                Value::ComplexMatrix(m) => {
                    let std_m = m.as_standard_layout();
                    let py_arr = std_m.to_pyarray(py);
                    Ok(py_arr.into_any())
                }
                Value::Complex(re, im) => {
                    let complex_type = py.import("builtins")?.getattr("complex")?;
                    Ok(complex_type.call1((*re, *im))?)
                }
                Value::CellArray(v) => {
                    let mut list = Vec::with_capacity(v.len());
                    for item in v.iter() {
                        list.push(Self::value_to_py(py, item)?);
                    }
                    Ok(PyList::new(py, list)?.into_any())
                }
                Value::Struct(map) => {
                    let dict = PyDict::new(py);
                    for (k, v) in map.iter() {
                        dict.set_item(k, Self::value_to_py(py, v)?)?;
                    }
                    Ok(dict.into_any())
                }
                Value::FunctionHandle(name) => Ok(PyString::new(py, name).into_any()),
                _ => Ok(py.None().into_bound(py)),
            }
        }

        pub fn py_to_value(obj: &Bound<'_, PyAny>) -> PyResult<Value> {
            if obj.is_none() {
                return Ok(Value::Void);
            }

            // Check Python bool BEFORE f64 because Python `bool` is a subclass of `int`
            // and `PyBool::extract::<f64>()` would misconvert True/False to 1.0/0.0!
            if obj.is_instance_of::<PyBool>() {
                if let Ok(b) = obj.extract::<bool>() {
                    return Ok(Value::Bool(b));
                }
            }

            // Handle numpy arrays safely without `.as_slice().unwrap()` (non-contiguous safe)
            if let Ok(arr) = obj.downcast::<PyArray2<bool>>() {
                let nd = arr.to_owned_array().as_standard_layout().to_owned();
                if nd.len() == 1 {
                    if let Some(&b) = nd.iter().next() {
                        return Ok(Value::Bool(b));
                    }
                }
                return Ok(Value::LogicalMatrix(Arc::new(nd)));
            }
            if let Ok(arr) = obj.downcast::<PyArray1<bool>>() {
                let nd = arr.to_owned_array();
                if nd.len() == 1 {
                    if let Some(&b) = nd.iter().next() {
                        return Ok(Value::Bool(b));
                    }
                }
                let vec_data: Vec<bool> = nd.iter().copied().collect();
                let len = vec_data.len();
                if let Ok(mat) = Array2::from_shape_vec((1, len), vec_data) {
                    return Ok(Value::LogicalMatrix(Arc::new(mat)));
                }
            }
            if let Ok(arr) = obj.downcast::<PyArray2<f64>>() {
                let nd = arr.to_owned_array().as_standard_layout().to_owned();
                if nd.len() == 1 {
                    if let Some(&first) = nd.iter().next() {
                        return Ok(Value::Scalar(first));
                    }
                }
                return Ok(Value::Matrix(Arc::new(nd)));
            }
            if let Ok(arr) = obj.downcast::<PyArray1<f64>>() {
                let nd = arr.to_owned_array();
                if nd.len() == 1 {
                    if let Some(&first) = nd.iter().next() {
                        return Ok(Value::Scalar(first));
                    }
                }
                let vec_data: Vec<f64> = nd.iter().copied().collect();
                let len = vec_data.len();
                if let Ok(mat) = Array2::from_shape_vec((1, len), vec_data) {
                    return Ok(Value::Matrix(Arc::new(mat)));
                }
            }
            if let Ok(arr) = obj.downcast::<PyArray2<f32>>() {
                let nd = arr
                    .to_owned_array()
                    .mapv(|x| x as f64)
                    .as_standard_layout()
                    .to_owned();
                if nd.len() == 1 {
                    if let Some(&first) = nd.iter().next() {
                        return Ok(Value::Scalar(first));
                    }
                }
                return Ok(Value::Matrix(Arc::new(nd)));
            }
            if let Ok(arr) = obj.downcast::<PyArray1<f32>>() {
                let nd = arr.to_owned_array().mapv(|x| x as f64);
                if nd.len() == 1 {
                    if let Some(&first) = nd.iter().next() {
                        return Ok(Value::Scalar(first));
                    }
                }
                let vec_data: Vec<f64> = nd.iter().copied().collect();
                let len = vec_data.len();
                if let Ok(mat) = Array2::from_shape_vec((1, len), vec_data) {
                    return Ok(Value::Matrix(Arc::new(mat)));
                }
            }
            if let Ok(arr) = obj.downcast::<PyArray2<i64>>() {
                let nd = arr
                    .to_owned_array()
                    .mapv(|x| x as f64)
                    .as_standard_layout()
                    .to_owned();
                if nd.len() == 1 {
                    if let Some(&first) = nd.iter().next() {
                        return Ok(Value::Scalar(first));
                    }
                }
                return Ok(Value::Matrix(Arc::new(nd)));
            }
            if let Ok(arr) = obj.downcast::<PyArray1<i64>>() {
                let nd = arr.to_owned_array().mapv(|x| x as f64);
                if nd.len() == 1 {
                    if let Some(&first) = nd.iter().next() {
                        return Ok(Value::Scalar(first));
                    }
                }
                let vec_data: Vec<f64> = nd.iter().copied().collect();
                let len = vec_data.len();
                if let Ok(mat) = Array2::from_shape_vec((1, len), vec_data) {
                    return Ok(Value::Matrix(Arc::new(mat)));
                }
            }
            if let Ok(arr) = obj.downcast::<PyArray2<Complex64>>() {
                let nd = arr.to_owned_array().as_standard_layout().to_owned();
                if nd.len() == 1 {
                    if let Some(&c) = nd.iter().next() {
                        return Ok(Value::Complex(c.re, c.im));
                    }
                }
                return Ok(Value::ComplexMatrix(Arc::new(nd)));
            }
            if let Ok(arr) = obj.downcast::<PyArray1<Complex64>>() {
                let nd = arr.to_owned_array();
                if nd.len() == 1 {
                    if let Some(&c) = nd.iter().next() {
                        return Ok(Value::Complex(c.re, c.im));
                    }
                }
                let vec_data: Vec<Complex64> = nd.iter().copied().collect();
                let len = vec_data.len();
                if let Ok(mat) = Array2::from_shape_vec((1, len), vec_data) {
                    return Ok(Value::ComplexMatrix(Arc::new(mat)));
                }
            }

            if let Ok(c) = obj.downcast::<PyComplex>() {
                return Ok(Value::Complex(c.real(), c.imag()));
            }
            if let Ok(n) = obj.extract::<f64>() {
                return Ok(Value::Scalar(n));
            }
            if let Ok(s) = obj.extract::<String>() {
                return Ok(Value::String(Arc::new(s)));
            }
            if let Ok(b) = obj.extract::<bool>() {
                return Ok(Value::Bool(b));
            }

            if let Ok(list) = obj.downcast::<PyList>() {
                let mut v = Vec::with_capacity(list.len());
                for item in list {
                    v.push(Self::py_to_value(&item)?);
                }
                return Ok(Value::CellArray(Arc::new(v)));
            }
            if let Ok(tuple) = obj.downcast::<PyTuple>() {
                let mut v = Vec::with_capacity(tuple.len());
                for item in tuple {
                    v.push(Self::py_to_value(&item)?);
                }
                return Ok(Value::CellArray(Arc::new(v)));
            }
            if let Ok(dict) = obj.downcast::<PyDict>() {
                let mut map = HashMap::new();
                for (k, v) in dict {
                    let k_str = k.extract::<String>()?;
                    map.insert(k_str, Self::py_to_value(&v)?);
                }
                return Ok(Value::Struct(Arc::new(map)));
            }
            Ok(Value::Void)
        }
    }
}

#[cfg(not(feature = "python-bridge"))]
mod imp {
    use super::Value;

    pub struct PythonBridge;

    impl PythonBridge {
        pub fn call_plot(_x: &Value, _y: &Value) -> Result<(), String> {
            Ok(())
        }

        pub fn call_simulate(_model: &Value, _args: Vec<Value>) -> Result<(), String> {
            Err("Python runtime bridge is unavailable in pure-Rust/Wasm mode".to_string())
        }

        pub fn call_runtime_func(
            name: &str,
            _args: Vec<Value>,
            _nargout: usize,
        ) -> Result<Value, String> {
            Err(format!(
                "Python runtime bridge is unavailable in pure-Rust/Wasm mode (cannot invoke '{}')",
                name
            ))
        }
    }
}

pub use imp::PythonBridge;
