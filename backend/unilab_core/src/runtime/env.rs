use std::collections::{HashMap, HashSet};
use std::sync::{Arc, RwLock};
use crate::runtime::value::Value;

#[derive(Debug, Clone)]
pub struct Environment {
    pub vars: HashMap<String, Value>,
    pub globals: HashSet<String>,
    pub parent: Option<Arc<RwLock<Environment>>>,
}

impl Default for Environment {
    fn default() -> Self {
        Self::new()
    }
}

impl Environment {
    pub fn new() -> Self {
        Self {
            vars: HashMap::new(),
            globals: HashSet::new(),
            parent: None,
        }
    }

    pub fn with_parent(parent: Arc<RwLock<Environment>>) -> Self {
        Self {
            vars: HashMap::new(),
            globals: HashSet::new(),
            parent: Some(parent),
        }
    }

    pub fn get(&self, name: &str) -> Option<Value> {
        if self.globals.contains(name) {
            if let Some(val) = self.get_from_user_root(name) {
                return Some(val);
            }
        }
        if let Some(val) = self.vars.get(name) {
            return Some(val.clone());
        }
        if let Some(parent) = &self.parent {
            let guard = parent.read().unwrap_or_else(|e| e.into_inner());
            return guard.get(name);
        }
        None
    }

    fn get_from_user_root(&self, name: &str) -> Option<Value> {
        if let Some(parent) = &self.parent {
            let p_guard = parent.read().unwrap_or_else(|e| e.into_inner());
            // Stop before the innermost builtins-only root if parent has a parent;
            // otherwise check current if parent is the builtins table.
            if p_guard.parent.is_some() {
                return p_guard.get_from_user_root(name);
            }
        }
        self.vars.get(name).cloned()
    }

    pub fn define(&mut self, name: String, value: Value) {
        if self.globals.contains(&name) {
            if self.define_in_user_root(&name, value.clone()) {
                return;
            }
        }
        self.vars.insert(name, value);
    }

    fn define_in_user_root(&mut self, name: &str, value: Value) -> bool {
        if let Some(parent) = &self.parent {
            let mut p_guard = parent.write().unwrap_or_else(|e| e.into_inner());
            if p_guard.parent.is_some() {
                return p_guard.define_in_user_root(name, value);
            }
        }
        self.vars.insert(name.to_string(), value);
        true
    }

    pub fn declare_global(&mut self, name: String, default_val: Value) {
        self.globals.insert(name.clone());
        if self.get_from_user_root(&name).is_none() {
            self.define_in_user_root(&name, default_val);
        }
    }

    pub fn assign(&mut self, name: &str, value: Value) -> bool {
        if self.vars.contains_key(name) {
            self.vars.insert(name.to_string(), value);
            return true;
        }
        if let Some(parent) = &self.parent {
            let mut guard = parent.write().unwrap_or_else(|e| e.into_inner());
            return guard.assign(name, value);
        }
        false
    }
}
