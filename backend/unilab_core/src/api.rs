use std::collections::HashMap;
use crate::runtime::eval::Evaluator;
use crate::runtime::value::Value;
use crate::parser::parse_unilab;
use crate::{ExecutionResult, PlotData};

pub struct UniLabEngine {
    pub evaluator: Evaluator,
}

impl Default for UniLabEngine {
    fn default() -> Self {
        Self::new()
    }
}

impl UniLabEngine {
    pub fn new() -> Self {
        Self {
            evaluator: Evaluator::new(),
        }
    }

    pub fn run_code(&mut self, code: &str) -> ExecutionResult {
        match parse_unilab(code) {
            Ok(program) => match self.evaluator.eval_program(&program) {
                Ok(_) => {
                    let out = if !self.evaluator.stdout.is_empty() {
                        self.evaluator.stdout.clone()
                    } else {
                        "Executed successfully".to_string()
                    };
                    let plots = self.evaluator.plots.clone();
                    self.evaluator.plots.clear();
                    self.evaluator.stdout.clear();
                    ExecutionResult {
                        success: true,
                        output: out,
                        error: None,
                        plots,
                    }
                }
                Err(e) => {
                    let out = self.evaluator.stdout.clone();
                    let plots = self.evaluator.plots.clone();
                    self.evaluator.plots.clear();
                    self.evaluator.stdout.clear();
                    ExecutionResult {
                        success: false,
                        output: out,
                        error: Some(e),
                        plots,
                    }
                }
            },
            Err(e) => ExecutionResult {
                success: false,
                output: String::new(),
                error: Some(e.to_string()),
                plots: Vec::new(),
            },
        }
    }

    pub fn get_workspace(&self) -> HashMap<String, String> {
        let env_guard = self.evaluator.env.read().unwrap_or_else(|e| e.into_inner());
        let mut map = HashMap::new();
        for (k, v) in &env_guard.vars {
            if !matches!(v, Value::Function { .. } | Value::FunctionHandle(_)) {
                map.insert(k.clone(), v.format_disp());
            }
        }
        map
    }
}

pub fn run_code(code: &str) -> ExecutionResult {
    let mut engine = UniLabEngine::new();
    engine.run_code(code)
}

#[cfg(feature = "wasm")]
pub mod wasm {
    use super::*;
    use wasm_bindgen::prelude::*;
    use std::sync::{Mutex, OnceLock};

    static WASM_SESSIONS: OnceLock<Mutex<HashMap<String, UniLabEngine>>> = OnceLock::new();

    fn get_wasm_sessions() -> &'static Mutex<HashMap<String, UniLabEngine>> {
        WASM_SESSIONS.get_or_init(|| Mutex::new(HashMap::new()))
    }

    #[wasm_bindgen]
    pub fn wasm_create_session(session_id: String) -> bool {
        let mut sessions = get_wasm_sessions().lock().unwrap_or_else(|e| e.into_inner());
        sessions.insert(session_id, UniLabEngine::new());
        true
    }

    #[wasm_bindgen]
    pub fn wasm_execute(session_id: String, code: String) -> String {
        let mut sessions = get_wasm_sessions().lock().unwrap_or_else(|e| e.into_inner());
        if let Some(engine) = sessions.get_mut(&session_id) {
            let res = engine.run_code(&code);
            serde_json::to_string(&res).unwrap_or_else(|_| "{\"success\":false,\"error\":\"Serialization failed\"}".to_string())
        } else {
            "{\"success\":false,\"error\":\"Session not found\"}".to_string()
        }
    }

    #[wasm_bindgen]
    pub fn wasm_get_workspace(session_id: String) -> String {
        let sessions = get_wasm_sessions().lock().unwrap_or_else(|e| e.into_inner());
        if let Some(engine) = sessions.get(&session_id) {
            let ws = engine.get_workspace();
            serde_json::to_string(&ws).unwrap_or_else(|_| "{}".to_string())
        } else {
            "{\"error\":\"Session not found\"}".to_string()
        }
    }
}

#[cfg(feature = "wasm")]
pub use wasm::*;
