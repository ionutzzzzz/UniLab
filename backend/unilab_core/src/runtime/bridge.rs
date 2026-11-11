use crate::runtime::value::Value;
use crate::runtime::env::Environment;
use std::sync::{Arc, RwLock};
use std::cell::RefCell;

thread_local! {
    pub static ACTIVE_ENV: RefCell<Option<Arc<RwLock<Environment>>>> = RefCell::new(None);
}

#[cfg(feature = "python-bridge")]
mod imp {
    use super::Value;
    use crate::runtime::env::Environment;
    use ndarray::Array2;
    use num_complex::Complex64;
    use numpy::{PyArray1, PyArray2, PyArrayMethods, ToPyArray};
    use pyo3::IntoPyObjectExt;
    use pyo3::prelude::*;
    use pyo3::types::{PyBool, PyComplex, PyComplexMethods, PyDict, PyList, PyString, PyTuple};
    use std::collections::HashMap;
    use std::sync::{Arc, OnceLock, RwLock};

    static PYTHON_PATH_INIT: OnceLock<()> = OnceLock::new();

    pub struct PythonBridge;

    impl PythonBridge {
        fn setup_python_path(py: Python<'_>) {
            PYTHON_PATH_INIT.get_or_init(|| {
                let _ = (|| -> PyResult<()> {
                    let sys = py.import("sys")?;
                    let path = sys.getattr("path")?;
                    let existing: Vec<String> = path.extract().unwrap_or_default();

                    let mut paths = vec![
                        ".".to_string(),
                        "..".to_string(),
                        "backend".to_string(),
                        "/usr/local/lib/python3.13/dist-packages".to_string(),
                        "/usr/lib/python3/dist-packages".to_string(),
                        "/usr/lib/python3.13/dist-packages".to_string(),
                    ];

                    if let Ok(vi) = sys.getattr("version_info") {
                        if let (Ok(major), Ok(minor)) = (vi.getattr("major"), vi.getattr("minor")) {
                            if let (Ok(maj), Ok(min)) = (major.extract::<u32>(), minor.extract::<u32>()) {
                                paths.push(format!("/usr/lib/python{}.{}/dist-packages", maj, min));
                                paths.push(format!("/usr/local/lib/python{}.{}/dist-packages", maj, min));
                                paths.push(format!("/usr/lib/python{}.{}", maj, min));
                            }
                        }
                    }

                    if let Ok(cwd) = std::env::current_dir() {
                        paths.push(cwd.to_string_lossy().to_string());
                        if let Some(parent) = cwd.parent() {
                            paths.push(parent.to_string_lossy().to_string());
                        }
                    }

                    if let Ok(site) = py.import("site") {
                        if let Ok(site_pkgs) = site.call_method0("getsitepackages") {
                            if let Ok(pkgs) = site_pkgs.extract::<Vec<String>>() {
                                paths.extend(pkgs);
                            }
                        }
                        if let Ok(user_site) = site.call_method0("getusersitepackages") {
                            if let Ok(pkg) = user_site.extract::<String>() {
                                paths.push(pkg);
                            }
                        }
                    }

                    if let Ok(home) = std::env::var("HOME") {
                        let home_path = std::path::Path::new(&home);
                        for v in &["3.13", "3.12", "3.11", "3.10"] {
                            let user_p = home_path.join(".local/lib").join(format!("python{}", v)).join("site-packages");
                            if user_p.exists() {
                                paths.push(user_p.to_string_lossy().to_string());
                            }
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

        pub fn call_simulate(model: &Value, args: Vec<Value>) -> Result<(), String> {
            Python::with_gil(|py| -> PyResult<()> {
                Self::setup_python_path(py);

                let sim_mod = match py.import("core.simulation.engine") {
                    Ok(m) => m,
                    Err(_) => py.import("backend.core.simulation.engine")?,
                };

                let unilab_simulate_func = sim_mod.getattr("unilab_simulate")?;

                let mut py_args = Vec::new();
                py_args.push(Self::value_to_py(py, model)?);
                for arg in args {
                    py_args.push(Self::value_to_py(py, &arg)?);
                }

                let _ = unilab_simulate_func.call1(PyTuple::new(py, py_args)?)?;
                Ok(())
            })
            .map_err(|e| e.to_string())
        }

        pub fn rust_func_to_py_callable<'py>(
            py: Python<'py>,
            func_val: Value,
            env_arc: Arc<RwLock<Environment>>,
        ) -> PyResult<Bound<'py, PyAny>> {
            let py_callable =
                pyo3::types::PyCFunction::new_closure(py, None, None, move |args, _kwargs| {
                    let py = args.py();

                    let mut rust_args = Vec::new();
                    for item in args.iter() {
                        rust_args.push(Self::py_to_value(&item)?);
                    }

                    let mut evaluator =
                        crate::runtime::eval::Evaluator::new_with_env(env_arc.clone());

                    let nargout = 1;
                    let res_val = evaluator
                        .call_function(func_val.clone(), rust_args, nargout)
                        .map_err(|e| PyErr::new::<pyo3::exceptions::PyRuntimeError, _>(e))?;

                    let py_res = Self::value_to_py(py, &res_val)?;
                    Ok::<PyObject, PyErr>(py_res.unbind())
                })?;

            Ok(py_callable.into_any())
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
                    let c = PyComplex::from_doubles(py, *re, *im);
                    Ok(c.into_any())
                }
                Value::CellArray(v) | Value::List(v) => {
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
                Value::FunctionHandle(name) => {
                    let resolved_func = crate::runtime::bridge::ACTIVE_ENV.with(|env| {
                        if let Some(env_arc) = &*env.borrow() {
                            if let Some(f_val) = env_arc.read().unwrap().get(name) {
                                match f_val {
                                    Value::Function { .. } | Value::AnonymousFunction { .. } => {
                                        return Some((f_val, env_arc.clone()));
                                    }
                                    _ => {}
                                }
                            }
                        }
                        None
                    });

                    if let Some((f_val, env_arc)) = resolved_func {
                        Self::rust_func_to_py_callable(py, f_val, env_arc)
                    } else {
                        Ok(PyString::new(py, name).into_any())
                    }
                }
                Value::Function { .. } | Value::AnonymousFunction { .. } => {
                    let env_arc_opt =
                        crate::runtime::bridge::ACTIVE_ENV.with(|env| env.borrow().clone());
                    if let Some(env_arc) = env_arc_opt {
                        Self::rust_func_to_py_callable(py, val.clone(), env_arc)
                    } else {
                        Ok(py.None().into_bound(py))
                    }
                }
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

            if let Ok(f) = obj.extract::<f64>() {
                return Ok(Value::Scalar(f));
            }
            if let Ok(s) = obj.extract::<String>() {
                return Ok(Value::String(Arc::new(s)));
            }
            if let Ok(list) = obj.downcast::<PyList>() {
                let mut v = Vec::with_capacity(list.len());
                for item in list {
                    v.push(Self::py_to_value(&item)?);
                }
                return Ok(Value::List(Arc::new(v)));
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
