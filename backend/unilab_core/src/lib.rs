pub mod parser;
pub mod runtime;
pub mod api;

#[cfg(feature = "python-bridge")]
pub mod ffi;

pub use parser::ast;
pub use parser::parse_unilab;
pub use api::{run_code, UniLabEngine};
pub use runtime::value::Value;
pub use runtime::env::Environment;
pub use runtime::eval::Evaluator;

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

#[cfg(feature = "python-bridge")]
mod py_bindings {
    use super::*;
    use pyo3::prelude::*;
    use std::collections::HashMap;
    use std::sync::{Mutex, OnceLock};

    static SESSIONS: OnceLock<Mutex<HashMap<String, Evaluator>>> = OnceLock::new();

    fn get_sessions() -> &'static Mutex<HashMap<String, Evaluator>> {
        SESSIONS.get_or_init(|| Mutex::new(HashMap::new()))
    }

    #[pyfunction]
    pub fn rust_create_session(session_id: String) -> PyResult<bool> {
        let mut sessions = get_sessions().lock().unwrap_or_else(|e| e.into_inner());
        sessions.insert(session_id, Evaluator::new());
        Ok(true)
    }

    #[pyfunction]
    pub fn rust_run_code_session(session_id: String, code: String) -> PyResult<String> {
        let mut sessions = get_sessions().lock().unwrap_or_else(|e| e.into_inner());
        let evaluator = sessions.get_mut(&session_id).ok_or_else(|| {
            PyErr::new::<pyo3::exceptions::PyKeyError, _>("Session not found")
        })?;

        let res = match parse_unilab(&code) {
            Ok(program) => {
                match evaluator.eval_program(&program) {
                    Ok(_) => {
                        let out = if !evaluator.stdout.is_empty() {
                            evaluator.stdout.clone()
                        } else {
                            "Executed successfully".to_string()
                        };
                        let plots = evaluator.plots.clone();
                        evaluator.plots.clear();
                        evaluator.stdout.clear();
                        ExecutionResult {
                            success: true,
                            output: out,
                            error: None,
                            plots,
                        }
                    }
                    Err(e) => {
                        let out = evaluator.stdout.clone();
                        let plots = evaluator.plots.clone();
                        evaluator.plots.clear();
                        evaluator.stdout.clear();
                        ExecutionResult {
                            success: false,
                            output: out,
                            error: Some(e),
                            plots,
                        }
                    }
                }
            }
            Err(e) => ExecutionResult {
                success: false,
                output: String::new(),
                error: Some(e.to_string()),
                plots: Vec::new(),
            },
        };

        Ok(serde_json::to_string(&res).unwrap_or_else(|_| "{}".to_string()))
    }

    #[pymodule]
    fn unilab_rust_core(m: &Bound<'_, PyModule>) -> PyResult<()> {
        m.add_function(wrap_pyfunction!(rust_create_session, m)?)?;
        m.add_function(wrap_pyfunction!(rust_run_code_session, m)?)?;
        Ok(())
    }
}

#[cfg(feature = "python-bridge")]
pub use py_bindings::*;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_keyword_boundary_identifiers() {
        let code = "end_time = 5; return_rate = 10; for_idx = 1; clear_flag = 2; if_valid = 3;";
        let res = run_code(code);
        assert!(res.success, "Failed with error: {:?}", res.error);
    }

    #[test]
    fn test_matrix_space_separation() {
        // [1 -2] should produce 1 row with 2 elements: [1.0, -2.0]
        let mut eval = Evaluator::new();
        let prog1 = parse_unilab("A = [1 -2];").expect("parse [1 -2]");
        eval.eval_program(&prog1).expect("eval [1 -2]");
        let a_val = eval.env.read().unwrap().get("A").expect("get A");
        if let Value::Matrix(m) = a_val {
            assert_eq!(m.nrows(), 1);
            assert_eq!(m.ncols(), 2);
            assert_eq!(m[[0, 0]], 1.0);
            assert_eq!(m[[0, 1]], -2.0);
        } else {
            panic!("Expected matrix for A, got {:?}", a_val);
        }

        // [1 - 2] should produce 1 element: [-1.0]
        let prog2 = parse_unilab("B = [1 - 2];").expect("parse [1 - 2]");
        eval.eval_program(&prog2).expect("eval [1 - 2]");
        let b_val = eval.env.read().unwrap().get("B").expect("get B");
        if let Value::Matrix(m) = b_val {
            assert_eq!(m.len(), 1);
            assert_eq!(m[[0, 0]], -1.0);
        } else {
            panic!("Expected matrix for B, got {:?}", b_val);
        }

        // [1-2] should produce 1 element: [-1.0]
        let prog3 = parse_unilab("C = [1-2];").expect("parse [1-2]");
        eval.eval_program(&prog3).expect("eval [1-2]");
        let c_val = eval.env.read().unwrap().get("C").expect("get C");
        if let Value::Matrix(m) = c_val {
            assert_eq!(m.len(), 1);
            assert_eq!(m[[0, 0]], -1.0);
        } else {
            panic!("Expected matrix for C, got {:?}", c_val);
        }
    }

    #[test]
    fn test_transposed_matrix_addition() {
        // A' and B' produce transposed views. Adding them must not panic and must produce standard layout result.
        let mut eval = Evaluator::new();
        let code = "A = [1, 2; 3, 4]; B = [5, 6; 7, 8]; C = (A') + (B');";
        let prog = parse_unilab(code).expect("parse");
        eval.eval_program(&prog).expect("eval");
        let c_val = eval.env.read().unwrap().get("C").expect("get C");
        if let Value::Matrix(m) = c_val {
            assert_eq!(m.nrows(), 2);
            assert_eq!(m.ncols(), 2);
            // A' is [1, 3; 2, 4], B' is [5, 7; 6, 8]
            // Sum is [6, 10; 8, 12]
            assert_eq!(m[[0, 0]], 6.0);
            assert_eq!(m[[0, 1]], 10.0);
            assert_eq!(m[[1, 0]], 8.0);
            assert_eq!(m[[1, 1]], 12.0);
        } else {
            panic!("Expected matrix for C, got {:?}", c_val);
        }
    }

    #[test]
    fn test_column_major_linear_indexing() {
        let mut eval = Evaluator::new();
        let code = "A = [10, 20; 30, 40]; x1 = A(1); x2 = A(2); x3 = A(3); x4 = A(4);";
        let prog = parse_unilab(code).expect("parse");
        eval.eval_program(&prog).expect("eval");
        assert_eq!(eval.env.read().unwrap().get("x1"), Some(Value::Scalar(10.0)));
        assert_eq!(eval.env.read().unwrap().get("x2"), Some(Value::Scalar(30.0))); // Column-major!
        assert_eq!(eval.env.read().unwrap().get("x3"), Some(Value::Scalar(20.0))); // Column-major!
        assert_eq!(eval.env.read().unwrap().get("x4"), Some(Value::Scalar(40.0)));

        // Index out of bounds should error cleanly, not panic
        let err_prog = parse_unilab("bad = A(5);").unwrap();
        assert!(eval.eval_program(&err_prog).is_err());
        let zero_prog = parse_unilab("bad0 = A(0);").unwrap();
        assert!(eval.eval_program(&zero_prog).is_err());
    }

    #[test]
    fn test_control_flow_break_continue_return() {
        let mut eval = Evaluator::new();
        
        // Break
        let code_break = "acc = 0; for i = 1:5; if i == 3; break; end; acc = i; end;";
        let prog = parse_unilab(code_break).expect("parse");
        eval.eval_program(&prog).expect("eval");
        assert_eq!(eval.env.read().unwrap().get("acc"), Some(Value::Scalar(2.0)));

        // Continue
        let code_cont = "s = 0; for i = 1:5; if i == 3; continue; end; s = s + i; end;";
        let prog = parse_unilab(code_cont).expect("parse");
        eval.eval_program(&prog).expect("eval");
        assert_eq!(eval.env.read().unwrap().get("s"), Some(Value::Scalar(12.0))); // 1 + 2 + 4 + 5 = 12

        // Nested return inside function
        let code_ret = r#"
function y = test_ret(x)
    if x < 0
        y = -1;
        return;
    end
    y = 1;
end
res_neg = test_ret(-5);
res_pos = test_ret(5);
"#;
        let prog = parse_unilab(code_ret).expect("parse");
        eval.eval_program(&prog).expect("eval");
        assert_eq!(eval.env.read().unwrap().get("res_neg"), Some(Value::Scalar(-1.0)));
        assert_eq!(eval.env.read().unwrap().get("res_pos"), Some(Value::Scalar(1.0)));
    }

    #[test]
    fn test_all_any_det_inv() {
        let mut eval = Evaluator::new();
        let code = r#"
m_all_true = all([1, 1; 1, 1]);
m_all_false = all([1, 0; 1, 1]);
m_any_true = any([0, 0; 0, 1]);
m_any_false = any([0, 0; 0, 0]);
d = det([1, 2; 3, 4]);
inv_m = inv([1, 2; 3, 4]);
prod_val = prod([2, 3, 4]);
"#;
        let prog = parse_unilab(code).expect("parse");
        eval.eval_program(&prog).expect("eval");
        assert_eq!(eval.env.read().unwrap().get("m_all_true"), Some(Value::Bool(true)));
        assert_eq!(eval.env.read().unwrap().get("m_all_false"), Some(Value::Bool(false)));
        assert_eq!(eval.env.read().unwrap().get("m_any_true"), Some(Value::Bool(true)));
        assert_eq!(eval.env.read().unwrap().get("m_any_false"), Some(Value::Bool(false)));
        assert_eq!(eval.env.read().unwrap().get("d"), Some(Value::Scalar(-2.0)));
        assert_eq!(eval.env.read().unwrap().get("prod_val"), Some(Value::Scalar(24.0)));

        if let Some(Value::Matrix(inv_arr)) = eval.env.read().unwrap().get("inv_m") {
            assert_eq!(inv_arr.dim(), (2, 2));
            assert!((inv_arr[[0, 0]] - (-2.0)).abs() < 1e-9);
            assert!((inv_arr[[0, 1]] - 1.0).abs() < 1e-9);
            assert!((inv_arr[[1, 0]] - 1.5).abs() < 1e-9);
            assert!((inv_arr[[1, 1]] - (-0.5)).abs() < 1e-9);
        } else {
            panic!("Expected matrix for inv_m");
        }
    }

    #[test]
    fn test_stdout_capture() {
        let mut eval = Evaluator::new();
        let code = r#"
disp('hello');
fprintf('val: %d\n', 42);
val = 100
suppressed = 200;
"#;
        let prog = parse_unilab(code).expect("parse");
        eval.eval_program(&prog).expect("eval");
        assert!(eval.stdout.contains("hello"));
        assert!(eval.stdout.contains("val: 42"));
        assert!(eval.stdout.contains("val =\n    100"));
        assert!(!eval.stdout.contains("suppressed ="));
    }
}
