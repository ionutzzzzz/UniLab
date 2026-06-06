use crate::{Evaluator, ExecutionResult, PlotData};
use crate::parser::parse_unilab;

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