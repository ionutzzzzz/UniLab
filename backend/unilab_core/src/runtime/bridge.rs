use pyo3::prelude::*;
use pyo3::types::{PyList, PyString, PyDict, PyTuple};
use pyo3::IntoPyObjectExt;
use numpy::{ToPyArray, PyArray2, PyArrayMethods};
use crate::runtime::value::Value;
use std::collections::HashMap;

pub struct PythonBridge;

impl PythonBridge {
    pub fn call_plot(x: &Value, y: &Value) -> PyResult<()> {
        Python::with_gil(|py| {
            let plt = py.import("matplotlib.pyplot")?;
            
            let py_x = Self::value_to_py(py, x)?;
            let py_y = Self::value_to_py(py, y)?;
            
            plt.call_method1("plot", (py_x, py_y))?;
            plt.call_method0("show")?;
            Ok(())
        })
    }

    pub fn call_simulate(model: &Value, args: Vec<Value>) -> PyResult<()> {
        Python::with_gil(|py| {
            let engine = py.import("backend.core.simulation.engine")?;
            
            let py_model = Self::value_to_py(py, model)?;
            let mut py_args = Vec::new();
            for arg in args {
                py_args.push(Self::value_to_py(py, &arg)?);
            }
            
            engine.call_method1("unilab_simulate", (py_model, PyTuple::new(py, py_args)?))?;
            Ok(())
        })
    }

    pub fn call_runtime_func(name: &str, args: Vec<Value>) -> PyResult<Value> {
        Python::with_gil(|py| {
            let sys = py.import("sys")?;
            sys.getattr("path")?.call_method1("append", (".",))?;
            sys.getattr("path")?.call_method1("append", ("..",))?;

            let rt = match py.import("core.runtime") {
                Ok(module) => module,
                Err(_) => py.import("backend.core.runtime")?,
            };

            let mut py_args = Vec::new();
            for arg in args {
                py_args.push(Self::value_to_py(py, &arg)?);
            }

            let res = rt.call_method1(name, PyTuple::new(py, py_args)?)?;
            Self::py_to_value(&res)
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
        if let Ok(n) = obj.extract::<f64>() {
            return Ok(Value::Scalar(n));
        }
        if let Ok(s) = obj.extract::<String>() {
            return Ok(Value::String(s));
        }
        if let Ok(b) = obj.extract::<bool>() {
            return Ok(Value::Bool(b));
        }
        if let Ok(arr) = obj.downcast::<PyArray2<f64>>() {
            let nd = arr.to_owned_array();
            return Ok(Value::Matrix(nd));
        }
        if let Ok(list) = obj.downcast::<PyList>() {
            let mut v = Vec::new();
            for item in list {
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
