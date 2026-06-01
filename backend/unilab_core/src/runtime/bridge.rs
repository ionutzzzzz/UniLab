use pyo3::prelude::*;
use pyo3::types::{PyList, PyString, PyDict, PyTuple};
use pyo3::IntoPyObjectExt;
use numpy::{ToPyArray, PyArray1, PyArray2, PyArrayMethods};
use crate::runtime::value::Value;
use std::collections::HashMap;
use num_complex::Complex64;

pub struct PythonBridge;

impl PythonBridge {
    fn setup_python_path(py: Python) -> PyResult<()> {
        let sys = py.import("sys")?;
        let path = sys.getattr("path")?;
        
        let mut paths = vec![".".to_string(), "..".to_string(), "backend".to_string()];
        
        if let Ok(cwd) = std::env::current_dir() {
            paths.push(cwd.to_string_lossy().to_string());
            if let Some(parent) = cwd.parent() {
                paths.push(parent.to_string_lossy().to_string());
            }
        }
        
        for p in paths {
            path.call_method1("insert", (0, p))?;
        }
        Ok(())
    }

    pub fn call_plot(x: &Value, y: &Value) -> PyResult<()> {
        Python::with_gil(|py| {
            Self::setup_python_path(py)?;
            let plt = py.import("matplotlib.pyplot")?;
            
            let py_x = match x {
                Value::Matrix(m) if m.nrows() == 1 || m.ncols() == 1 => {
                    let flat = m.iter().cloned().collect::<Vec<f64>>();
                    flat.into_py_any(py)?.into_bound(py)
                }
                _ => Self::value_to_py(py, x)?,
            };
            let py_y = match y {
                Value::Matrix(m) if m.nrows() == 1 || m.ncols() == 1 => {
                    let flat = m.iter().cloned().collect::<Vec<f64>>();
                    flat.into_py_any(py)?.into_bound(py)
                }
                _ => Self::value_to_py(py, y)?,
            };
            
            plt.call_method1("plot", (py_x, py_y))?;
            plt.call_method0("show")?;
            Ok(())
        })
    }

    pub fn call_simulate(model: &Value, args: Vec<Value>) -> PyResult<()> {
        Python::with_gil(|py| {
            Self::setup_python_path(py)?;
            let engine = match py.import("core.simulation.engine") {
                Ok(m) => m,
                Err(_) => py.import("backend.core.simulation.engine")?,
            };
            
            let py_model = Self::value_to_py(py, model)?;
            let mut py_args = Vec::new();
            for arg in args {
                py_args.push(Self::value_to_py(py, &arg)?);
            }
            
            engine.call_method1("unilab_simulate", (py_model, PyTuple::new(py, py_args)?))?;
            Ok(())
        })
    }

    pub fn call_runtime_func(name: &str, args: Vec<Value>, nargout: usize) -> PyResult<Value> {
        Python::with_gil(|py| {
            Self::setup_python_path(py)?;

            let rt = match py.import("core.runtime") {
                Ok(module) => module,
                Err(_) => py.import("backend.core.runtime")?,
            };

            // Set nargout in Python context
            if let Ok(ctx) = rt.getattr("_unilab_nargout_ctx") {
                let _ = ctx.call_method1("set", (nargout,));
            }

            let mut py_args = Vec::new();
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
    }

    pub fn value_to_py<'py>(py: Python<'py>, val: &Value) -> PyResult<Bound<'py, PyAny>> {
        match val {
            Value::Scalar(n) => Ok(n.into_py_any(py)?.into_bound(py)),
            Value::String(s) => Ok(PyString::new(py, s).into_any()),
            Value::Bool(b) => Ok(b.into_py_any(py)?.into_bound(py)),
            Value::Matrix(m) => {
                let py_arr = m.to_pyarray(py);
                Ok(py_arr.into_any())
            },
            Value::ComplexMatrix(m) => {
                let py_arr = m.to_pyarray(py);
                Ok(py_arr.into_any())
            },
            Value::Complex(re, im) => {
                let complex_type = py.import("builtins")?.getattr("complex")?;
                Ok(complex_type.call1((*re, *im))?)
            }
            Value::CellArray(v) => {
                let mut list = Vec::new();
                for item in v {
                    list.push(Self::value_to_py(py, item)?);
                }
                Ok(PyList::new(py, list)?.into_any())
            }
            Value::Struct(map) => {
                let dict = PyDict::new(py);
                for (k, v) in map {
                    dict.set_item(k, Self::value_to_py(py, v)?)?;
                }
                Ok(dict.into_any())
            }
            Value::FunctionHandle(name) => {
                Ok(PyString::new(py, name).into_any())
            }
            _ => Ok(py.None().into_bound(py)),
        }
    }

    pub fn py_to_value(obj: &Bound<'_, PyAny>) -> PyResult<Value> {
        if obj.is_none() {
            return Ok(Value::Void);
        }
        
        // Handle numpy arrays first to avoid TypeError during extract::<f64>
        if let Ok(arr) = obj.downcast::<PyArray2<f64>>() {
            let nd = arr.to_owned_array();
            if nd.len() == 1 { return Ok(Value::Scalar(nd.as_slice().unwrap()[0])); }
            return Ok(Value::Matrix(nd));
        }
        if let Ok(arr) = obj.downcast::<PyArray1<f64>>() {
            let nd = arr.to_owned_array();
            if nd.len() == 1 { return Ok(Value::Scalar(nd.as_slice().unwrap()[0])); }
            let len = nd.len();
            return Ok(Value::Matrix(nd.into_shape((1, len)).unwrap()));
        }
        if let Ok(arr) = obj.downcast::<PyArray2<f32>>() {
            let nd = arr.to_owned_array().mapv(|x| x as f64);
            if nd.len() == 1 { return Ok(Value::Scalar(nd.as_slice().unwrap()[0])); }
            return Ok(Value::Matrix(nd));
        }
        if let Ok(arr) = obj.downcast::<PyArray1<f32>>() {
            let nd = arr.to_owned_array().mapv(|x| x as f64);
            if nd.len() == 1 { return Ok(Value::Scalar(nd.as_slice().unwrap()[0])); }
            let len = nd.len();
            return Ok(Value::Matrix(nd.into_shape((1, len)).unwrap()));
        }
        if let Ok(arr) = obj.downcast::<PyArray2<i64>>() {
            let nd = arr.to_owned_array().mapv(|x| x as f64);
            if nd.len() == 1 { return Ok(Value::Scalar(nd.as_slice().unwrap()[0])); }
            return Ok(Value::Matrix(nd));
        }
        if let Ok(arr) = obj.downcast::<PyArray1<i64>>() {
            let nd = arr.to_owned_array().mapv(|x| x as f64);
            if nd.len() == 1 { return Ok(Value::Scalar(nd.as_slice().unwrap()[0])); }
            let len = nd.len();
            return Ok(Value::Matrix(nd.into_shape((1, len)).unwrap()));
        }
        if let Ok(arr) = obj.downcast::<PyArray2<Complex64>>() {
            let nd = arr.to_owned_array();
            if nd.len() == 1 { 
                let c = nd.as_slice().unwrap()[0];
                return Ok(Value::Complex(c.re, c.im));
            }
            return Ok(Value::ComplexMatrix(nd));
        }
        if let Ok(arr) = obj.downcast::<PyArray1<Complex64>>() {
            let nd = arr.to_owned_array();
            if nd.len() == 1 { 
                let c = nd.as_slice().unwrap()[0];
                return Ok(Value::Complex(c.re, c.im));
            }
            let len = nd.len();
            return Ok(Value::ComplexMatrix(nd.into_shape((1, len)).unwrap()));
        }

        if let Ok(n) = obj.extract::<f64>() {
            return Ok(Value::Scalar(n));
        }
        if let Ok(s) = obj.extract::<String>() {
            return Ok(Value::String(s));
        }
        if let Ok(b) = obj.extract::<bool>() {
            return Ok(Value::Bool(b));
        }
        
        if let Ok(list) = obj.downcast::<PyList>() {
            let mut v = Vec::new();
            for item in list {
                v.push(Self::py_to_value(&item)?);
            }
            return Ok(Value::CellArray(v));
        }
        if let Ok(tuple) = obj.downcast::<PyTuple>() {
            let mut v = Vec::new();
            for item in tuple {
                v.push(Self::py_to_value(&item)?);
            }
            return Ok(Value::CellArray(v));
        }
        if let Ok(dict) = obj.downcast::<PyDict>() {
            let mut map = HashMap::new();
            for (k, v) in dict {
                let k_str = k.extract::<String>()?;
                map.insert(k_str, Self::py_to_value(&v)?);
            }
            return Ok(Value::Struct(map));
        }
        Ok(Value::Void)
    }
}
