use std::collections::HashMap;
use std::sync::{Arc, RwLock};
use crate::runtime::value::Value;

#[derive(Debug, Clone)]
pub struct Environment {
    pub vars: HashMap<String, Value>,
    pub parent: Option<Arc<RwLock<Environment>>>,
}

impl Environment {
    pub fn new() -> Self {
        Self {
            vars: HashMap::new(),
            parent: None,
        }
    }

    pub fn with_parent(parent: Arc<RwLock<Environment>>) -> Self {
        Self {
            vars: HashMap::new(),
            parent: Some(parent),
        }
    }

    pub fn get(&self, name: &str) -> Option<Value> {
        if let Some(val) = self.vars.get(name) {
            return Some(val.clone());
        }
        if let Some(parent) = &self.parent {
            return parent.read().unwrap().get(name);
        }
        None
    }

    pub fn define(&mut self, name: String, value: Value) {
        self.vars.insert(name, value);
    }

    pub fn assign(&mut self, name: &str, value: Value) -> bool {
        if self.vars.contains_key(name) {
            self.vars.insert(name.to_string(), value);
            return true;
        }
        if let Some(parent) = &self.parent {
            return parent.write().unwrap().assign(name, value);
        }
        false
    }
}
