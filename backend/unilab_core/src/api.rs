use crate::Evaluator;
use crate::parser::parse_unilab;
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ExecutionResult {
    pub success: bool,
    pub output: String,
    pub error: Option<String>,
    pub plots: Vec<PlotData>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct PlotData {
    pub plot_type: String, // "line", "scatter", etc.
    pub x: Vec<f64>,
    pub y: Vec<f64>,
    pub title: Option<String>,
    pub xlabel: Option<String>,
    pub ylabel: Option<String>,
}

pub fn run_code(code: &str) -> ExecutionResult {
    let mut evaluator = Evaluator::new();
    
    match parse_unilab(code) {
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
    }
}
