pub mod parser;
pub mod runtime;
pub mod api;
pub mod ffi;

pub use parser::ast;
pub use parser::parse_unilab;
pub use api::run_code;
pub use runtime::value::Value;
pub use runtime::env::Environment;
pub use runtime::eval::Evaluator;

use pyo3::prelude::*;
use std::collections::HashMap;
use std::sync::{Mutex, OnceLock};
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct PlotData {
    pub plot_type: String,
    pub x: Vec<f64>,
    pub y: Vec<f64>,
    pub title: Option<String>,
    pub xlabel: Option<String>,
    pub ylabel: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ExecutionResult {
    pub success: bool,
    pub output: String,
    pub error: Option<String>,
    pub plots: Vec<PlotData>,
}

static SESSIONS: OnceLock<Mutex<HashMap<String, Evaluator>>> = OnceLock::new();

fn get_sessions() -> &'static Mutex<HashMap<String, Evaluator>> {
    SESSIONS.get_or_init(|| Mutex::new(HashMap::new()))
}

#[pyfunction]
fn rust_create_session(session_id: String) -> PyResult<bool> {
    let mut sessions = get_sessions().lock().unwrap();
    sessions.insert(session_id, Evaluator::new());
    Ok(true)
}

#[pyfunction]
fn rust_run_code_session(session_id: String, code: String) -> PyResult<String> {
    let mut sessions = get_sessions().lock().unwrap();
    let evaluator = sessions.get_mut(&session_id).ok_or_else(|| {
        PyErr::new::<pyo3::exceptions::PyKeyError, _>("Session not found")
    })?;

    let res = match parse_unilab(&code) {
        Ok(program) => {
            match evaluator.eval_program(&program) {
                Ok(_) => ExecutionResult {
                    success: true,
                    output: "Executed successfully".to_string(),
                    error: None,
                    plots: evaluator.plots.clone(),
                },
                Err(e) => ExecutionResult {
                    success: false,
                    output: "".to_string(),
                    error: Some(e),
                    plots: evaluator.plots.clone(),
                },
            }
        }
        Err(e) => ExecutionResult {
            success: false,
            output: "".to_string(),
            error: Some(e.to_string()),
            plots: Vec::new(),
        },
    };
    
    // Clear plots after retrieval
    evaluator.plots.clear();
    
    Ok(serde_json::to_string(&res).unwrap())
}

#[pymodule]
fn unilab_rust_core(m: &Bound<'_, PyModule>) -> PyResult<()> {
    m.add_function(wrap_pyfunction!(rust_create_session, m)?)?;
    m.add_function(wrap_pyfunction!(rust_run_code_session, m)?)?;
    Ok(())
}
