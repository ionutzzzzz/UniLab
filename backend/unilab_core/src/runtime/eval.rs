use crate::parser::ast::*;
use crate::runtime::value::Value;
use crate::runtime::env::Environment;
use std::sync::{Arc, RwLock};
use ndarray::Array2;
use std::path::PathBuf;
use std::fs;
use crate::PlotData;
use crate::runtime::bridge::PythonBridge;
use num_complex::Complex64;

#[cfg(not(target_arch = "wasm32"))]
#[derive(Clone, Copy, Debug)]
pub struct TimePoint(std::time::Instant);

#[cfg(target_arch = "wasm32")]
#[derive(Clone, Copy, Debug)]
pub struct TimePoint(f64);

impl TimePoint {
    pub fn now() -> Self {
        #[cfg(not(target_arch = "wasm32"))]
        {
            TimePoint(std::time::Instant::now())
        }
        #[cfg(target_arch = "wasm32")]
        {
            #[cfg(feature = "wasm")]
            {
                TimePoint(js_sys::Date::now())
            }
            #[cfg(not(feature = "wasm"))]
            {
                TimePoint(0.0)
            }
        }
    }

    pub fn elapsed_secs(&self) -> f64 {
        #[cfg(not(target_arch = "wasm32"))]
        {
            self.0.elapsed().as_secs_f64()
        }
        #[cfg(target_arch = "wasm32")]
        {
            #[cfg(feature = "wasm")]
            {
                (js_sys::Date::now() - self.0) / 1000.0
            }
            #[cfg(not(feature = "wasm"))]
            {
                0.0
            }
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub enum EvalOutcome {
    Value(Value),
    Break,
    Continue,
    Return(Value),
}

pub struct Evaluator {
    pub env: Arc<RwLock<Environment>>,
    pub search_paths: Vec<PathBuf>,
    pub plots: Vec<PlotData>,
    pub tic_time: Option<TimePoint>,
    pub end_stack: Vec<f64>,
    pub stdout: String,
}

impl Evaluator {
    pub fn new() -> Self {
        let mut builtins_env = Environment::new();
        Self::setup_builtins(&mut builtins_env);
        
        let env = Environment::with_parent(Arc::new(RwLock::new(builtins_env)));
        Self::new_with_env(Arc::new(RwLock::new(env)))
    }

    pub fn new_with_env(env: Arc<RwLock<Environment>>) -> Self {
        let mut search_paths = vec![PathBuf::from(".")];
        
        // Add stdlib libraries to search path
        let stdlib_path = PathBuf::from("stdlib/libraries");
        if stdlib_path.exists() {
            if let Ok(entries) = fs::read_dir(&stdlib_path) {
                for entry in entries.flatten() {
                    if entry.path().is_dir() {
                        search_paths.push(entry.path());
                    }
                }
            }
        } else {
            let backend_stdlib = PathBuf::from("backend/stdlib/libraries");
            if backend_stdlib.exists() {
                if let Ok(entries) = fs::read_dir(&backend_stdlib) {
                    for entry in entries.flatten() {
                        if entry.path().is_dir() {
                            search_paths.push(entry.path());
                        }
                    }
                }
            }
        }

        Self {
            env,
            search_paths,
            plots: Vec::new(),
            tic_time: None,
            end_stack: Vec::new(),
            stdout: String::new(),
        }
    }

    fn setup_builtins(env: &mut Environment) {
        // Constants
        env.define("pi".to_string(), Value::Scalar(std::f64::consts::PI));
        env.define("eps".to_string(), Value::Scalar(f64::EPSILON));
        env.define("i".to_string(), Value::Complex(0.0, 1.0));
        env.define("j".to_string(), Value::Complex(0.0, 1.0));
        env.define("inf".to_string(), Value::Scalar(f64::INFINITY));
        env.define("Inf".to_string(), Value::Scalar(f64::INFINITY));
        env.define("nan".to_string(), Value::Scalar(f64::NAN));
        env.define("NaN".to_string(), Value::Scalar(f64::NAN));
        env.define("true".to_string(), Value::Bool(true));
        env.define("false".to_string(), Value::Bool(false));

        // Built-ins
        let builtins = vec![
            "disp", "range", "size", "plot", "simulate", "linspace", "zeros", "ones", "eye",
            "rand", "randn", "randperm", "exp", "sin", "cos", "tan", "tanh", "sqrt", "abs", "log", "log10",
            "sum", "mean", "std", "var", "min", "max", "round", "floor", "ceil", "prod",
            "struct", "hold", "grid", "title", "xlabel", "ylabel", "legend", "subplot",
            "axis", "xlim", "ylim", "imagesc", "colorbar", "colormap", "factorial",
            "clc", "close", "tic", "toc", "pause", "find", "length", "mode", "reshape", "unique", "kron",
            "all", "any", "det", "inv",
            "figure", "gcf", "gca", "clf", "cla", "fprintf", "sprintf", "num2str",
            "deg2rad", "rad2deg", "trapz", "eig", "diag", "norm",
            "fopen", "fread", "fclose", "fwrite", "mod", "rem", "meshgrid",
            "real", "imag", "sort", "sign", "fft", "ifft",
            "sinh", "cosh", "tanh", "asinh", "acosh", "atanh",
            "ischar", "iscell", "isnumeric", "strcmp", "isequal",
            "argmin", "argmax", "isempty",
        ];

        for name in builtins {
            env.define(name.to_string(), Value::FunctionHandle(name.to_string()));
        }
    }

    pub fn eval_program(&mut self, program: &Program) -> Result<Value, String> {
        // Set active environment for Python bridge
        crate::runtime::bridge::ACTIVE_ENV.with(|env| {
            *env.borrow_mut() = Some(self.env.clone());
        });

        let result = self.eval_program_internal(program);

        // Clear active environment
        crate::runtime::bridge::ACTIVE_ENV.with(|env| {
            *env.borrow_mut() = None;
        });

        result
    }

    fn eval_program_internal(&mut self, program: &Program) -> Result<Value, String> {
        // Hoist all local functions first
        for stmt in &program.statements {
            if let Stmt::FunctionDef { name, params, returns, body } = stmt {
                let func = Value::Function {
                    name: name.clone(),
                    params: params.clone(),
                    returns: returns.clone(),
                    body: Arc::new(body.clone()),
                };
                self.env.write().unwrap_or_else(|e| e.into_inner()).define(name.clone(), func);
            }
        }

        let mut last_val = Value::Void;
        for stmt in &program.statements {
            if let Stmt::FunctionDef { .. } = stmt {
                continue;
            }
            match self.eval_statement(stmt)? {
                EvalOutcome::Value(v) => { last_val = v; }
                EvalOutcome::Return(v) => {
                    return Ok(if v != Value::Void { v } else { last_val });
                }
                EvalOutcome::Break | EvalOutcome::Continue => {
                    break;
                }
            }
        }
        Ok(last_val)
    }

    fn eval_block(&mut self, stmts: &[Stmt]) -> Result<EvalOutcome, String> {
        let mut last = Value::Void;
        for stmt in stmts {
            match self.eval_statement(stmt)? {
                EvalOutcome::Value(v) => { last = v; }
                early @ (EvalOutcome::Break | EvalOutcome::Continue | EvalOutcome::Return(_)) => {
                    return Ok(early);
                }
            }
        }
        Ok(EvalOutcome::Value(last))
    }

    fn eval_statement(&mut self, stmt: &Stmt) -> Result<EvalOutcome, String> {
        match stmt {
            Stmt::Expression { expr, suppressed } => {
                let val = self.eval_expression(expr)?;
                // Function handles without arguments are called if they are built-ins like clc
                let final_val = if let Value::FunctionHandle(name) = &val {
                    let zero_arg_commands = ["clc", "clear", "tic", "toc", "close"];
                    if zero_arg_commands.contains(&name.as_str()) {
                        self.call_function(val.clone(), Vec::new(), 1)?
                    } else {
                        val
                    }
                } else {
                    val
                };

                if !suppressed && final_val != Value::Void {
                    self.env.write().unwrap_or_else(|e| e.into_inner()).define("ans".to_string(), final_val.clone());
                    self.stdout.push_str(&format!("ans =\n    {}\n", final_val.format_disp()));
                }
                Ok(EvalOutcome::Value(final_val))
            }
            Stmt::Assignment { lhs, rhs, suppressed } => {
                let val = match rhs {
                    Expr::FunctionCall { func, args } => {
                        self.eval_function_call_internal(func, args, lhs.len())?
                    }
                    _ => self.eval_expression(rhs)?,
                };

                if lhs.len() > 1 {
                    if let Value::List(vals) = &val {
                        for (i, l) in lhs.iter().enumerate() {
                            if i < vals.len() {
                                self.assign_lhs(l, vals[i].clone())?;
                            } else {
                                self.assign_lhs(l, Value::Void)?;
                            }
                        }
                        if !suppressed && val != Value::Void {
                            self.stdout.push_str(&format!("ans =\n    {}\n", val.format_disp()));
                        }
                        return Ok(EvalOutcome::Value(val));
                    }
                }

                for l in lhs {
                    self.assign_lhs(l, val.clone())?;
                }

                if !suppressed && val != Value::Void {
                    if let Some(first_lhs) = lhs.first() {
                        let name = match first_lhs {
                            Expr::Identifier(n) => n.clone(),
                            _ => "ans".to_string(),
                        };
                        self.stdout.push_str(&format!("{} =\n    {}\n", name, val.format_disp()));
                    }
                }
                Ok(EvalOutcome::Value(val))
            }
            Stmt::If { condition, then_block, elseif_clauses, else_block } => {
                let cond_val = self.eval_expression(condition)?;
                if cond_val.is_truthy() {
                    return self.eval_block(then_block);
                }
                for (ei_cond, ei_block) in elseif_clauses {
                    if self.eval_expression(ei_cond)?.is_truthy() {
                        return self.eval_block(ei_block);
                    }
                }
                if let Some(block) = else_block {
                    return self.eval_block(block);
                }
                Ok(EvalOutcome::Value(Value::Void))
            }
            Stmt::For { var, iter, body } => {
                let iter_val = self.eval_expression(iter)?;
                match iter_val {
                    Value::Matrix(m) => {
                        let mut last = Value::Void;
                        for col in m.columns() {
                            let val = if col.len() == 1 {
                                Value::Scalar(col[0])
                            } else {
                                Value::Matrix(Arc::new(col.to_owned().insert_axis(ndarray::Axis(1))))
                            };
                            self.env.write().unwrap_or_else(|e| e.into_inner()).define(var.clone(), val);
                            match self.eval_block(body)? {
                                EvalOutcome::Value(v) => { last = v; }
                                EvalOutcome::Continue => continue,
                                EvalOutcome::Break => break,
                                ret @ EvalOutcome::Return(_) => return Ok(ret),
                            }
                        }
                        Ok(EvalOutcome::Value(last))
                    }
                    Value::ComplexMatrix(m) => {
                        let mut last = Value::Void;
                        for col in m.columns() {
                            let val = if col.len() == 1 {
                                Value::Complex(col[0].re, col[0].im)
                            } else {
                                Value::ComplexMatrix(Arc::new(col.to_owned().insert_axis(ndarray::Axis(1))))
                            };
                            self.env.write().unwrap_or_else(|e| e.into_inner()).define(var.clone(), val);
                            match self.eval_block(body)? {
                                EvalOutcome::Value(v) => { last = v; }
                                EvalOutcome::Continue => continue,
                                EvalOutcome::Break => break,
                                ret @ EvalOutcome::Return(_) => return Ok(ret),
                            }
                        }
                        Ok(EvalOutcome::Value(last))
                    }
                    Value::CellArray(v) => {
                        let mut last = Value::Void;
                        for item in v.iter() {
                            self.env.write().unwrap_or_else(|e| e.into_inner()).define(var.clone(), item.clone());
                            match self.eval_block(body)? {
                                EvalOutcome::Value(v) => { last = v; }
                                EvalOutcome::Continue => continue,
                                EvalOutcome::Break => break,
                                ret @ EvalOutcome::Return(_) => return Ok(ret),
                            }
                        }
                        Ok(EvalOutcome::Value(last))
                    }
                    _ => Err(format!("Cannot iterate over {:?}", iter_val)),
                }
            }
            Stmt::ParFor { var, iter, body } => {
                let iter_val = self.eval_expression(iter)?;
                match iter_val {
                    Value::Matrix(m) => {
                        let items: Vec<Value> = m.columns().into_iter().map(|col| {
                            if col.len() == 1 {
                                Value::Scalar(col[0])
                            } else {
                                Value::Matrix(Arc::new(col.to_owned().insert_axis(ndarray::Axis(1))))
                            }
                        }).collect();

                        #[cfg(feature = "python-bridge")]
                        {
                            use rayon::prelude::*;
                            items.into_par_iter().map(|val| {
                                let sub_env = Arc::new(RwLock::new(Environment::with_parent(self.env.clone())));
                                sub_env.write().unwrap_or_else(|e| e.into_inner()).define(var.clone(), val);
                                let mut sub_eval = Evaluator::new_with_env(sub_env);
                                sub_eval.eval_block(body)
                            }).collect::<Result<Vec<EvalOutcome>, String>>()?;
                        }
                        #[cfg(not(feature = "python-bridge"))]
                        {
                            for val in items {
                                let sub_env = Arc::new(RwLock::new(Environment::with_parent(self.env.clone())));
                                sub_env.write().unwrap_or_else(|e| e.into_inner()).define(var.clone(), val);
                                let mut sub_eval = Evaluator::new_with_env(sub_env);
                                sub_eval.eval_block(body)?;
                            }
                        }
                        
                        Ok(EvalOutcome::Value(Value::Void))
                    }
                    _ => Err(format!("Cannot parfor over {:?}", iter_val)),
                }
            }
            Stmt::While { condition, body } => {
                let mut last = Value::Void;
                while self.eval_expression(condition)?.is_truthy() {
                    match self.eval_block(body)? {
                        EvalOutcome::Value(v) => { last = v; }
                        EvalOutcome::Continue => continue,
                        EvalOutcome::Break => break,
                        ret @ EvalOutcome::Return(_) => return Ok(ret),
                    }
                }
                Ok(EvalOutcome::Value(last))
            }
            Stmt::Switch { expression, cases, otherwise } => {
                let switch_val = self.eval_expression(expression)?;
                let mut matched = false;
                for (case_expr, case_block) in cases {
                    let case_val = self.eval_expression(case_expr)?;
                    let is_match = match (&switch_val, &case_val) {
                        (Value::CellArray(items), _) => items.iter().any(|item| item == &case_val),
                        (_, Value::CellArray(items)) => items.iter().any(|item| item == &switch_val),
                        (a, b) => a == b,
                    };
                    if is_match {
                        matched = true;
                        return self.eval_block(case_block);
                    }
                }
                if !matched {
                    if let Some(other_block) = otherwise {
                        return self.eval_block(other_block);
                    }
                }
                Ok(EvalOutcome::Value(Value::Void))
            }
            Stmt::Try { try_block, catch_var, catch_block } => {
                match self.eval_block(try_block) {
                    Ok(outcome) => Ok(outcome),
                    Err(err_msg) => {
                        if let Some(var_name) = catch_var {
                            self.env.write().unwrap_or_else(|e| e.into_inner()).define(var_name.clone(), Value::String(Arc::new(err_msg)));
                        }
                        self.eval_block(catch_block)
                    }
                }
            }
            Stmt::FunctionDef { name, params, returns, body } => {
                let func = Value::Function {
                    name: name.clone(),
                    params: params.clone(),
                    returns: returns.clone(),
                    body: Arc::new(body.clone()),
                };
                self.env.write().unwrap_or_else(|e| e.into_inner()).define(name.clone(), func);
                Ok(EvalOutcome::Value(Value::Void))
            }
            Stmt::Clear(vars) => {
                if vars.is_empty() || vars.contains(&"all".to_string()) {
                    let mut keys_to_remove = Vec::new();
                    for (k, v) in self.env.read().unwrap_or_else(|e| e.into_inner()).vars.iter() {
                        if !matches!(v, Value::Function { .. }) && !matches!(v, Value::FunctionHandle(_)) {
                            keys_to_remove.push(k.clone());
                        }
                    }
                    let mut env = self.env.write().unwrap_or_else(|e| e.into_inner());
                    for k in keys_to_remove {
                        env.vars.remove(&k);
                    }
                } else {
                    for v in vars {
                        self.env.write().unwrap_or_else(|e| e.into_inner()).vars.remove(v);
                    }
                }
                Ok(EvalOutcome::Value(Value::Void))
            }
            Stmt::Global(vars) => {
                for v in vars {
                    self.env.write().unwrap_or_else(|e| e.into_inner()).declare_global(v.clone(), Value::Void);
                }
                Ok(EvalOutcome::Value(Value::Void))
            }
            Stmt::Import(_path) => Ok(EvalOutcome::Value(Value::Void)),
            Stmt::Export(_id) => Ok(EvalOutcome::Value(Value::Void)),
            Stmt::CommandCall { command, args } => {
                let arg_vals = args.iter().map(|a| Value::String(Arc::new(a.clone()))).collect();
                let res = self.call_function(Value::FunctionHandle(command.clone()), arg_vals, 0)?;
                Ok(EvalOutcome::Value(res))
            }
            Stmt::Return => Ok(EvalOutcome::Return(Value::Void)),
            Stmt::Break => Ok(EvalOutcome::Break),
            Stmt::Continue => Ok(EvalOutcome::Continue),
        }
    }

    fn assign_lhs(&mut self, l: &Expr, val: Value) -> Result<(), String> {
        match l {
            Expr::Identifier(name) => {
                self.env.write().unwrap_or_else(|e| e.into_inner()).define(name.clone(), val);
                Ok(())
            }
            Expr::FunctionCall { func, args } => {
                if let Expr::Identifier(name) = &**func {
                    let target_val_opt = self.env.read().unwrap_or_else(|e| e.into_inner()).get(name);
                    if let Some(target_val) = target_val_opt {
                        let end_vals = match &target_val {
                            Value::Matrix(m) => {
                                if args.len() == 1 { vec![m.len() as f64] }
                                else { vec![m.nrows() as f64, m.ncols() as f64] }
                            }
                            Value::ComplexMatrix(m) => {
                                if args.len() == 1 { vec![m.len() as f64] }
                                else { vec![m.nrows() as f64, m.ncols() as f64] }
                            }
                            Value::CellArray(v) => vec![v.len() as f64],
                            _ => Vec::new(),
                        };

                        let mut idx_vals = Vec::new();
                        for (i, a) in args.iter().enumerate() {
                            let mut current_ev = None;
                            if !end_vals.is_empty() {
                                let ev = if end_vals.len() == 1 { end_vals[0] }
                                         else if i < end_vals.len() { end_vals[i] }
                                         else { *end_vals.last().unwrap() };
                                current_ev = Some(ev);
                                self.end_stack.push(ev);
                            }
                            let res = self.eval_expression(a);
                            if current_ev.is_some() { self.end_stack.pop(); }
                            idx_vals.push(res?);
                        }

                        match target_val {
                            Value::Matrix(m_arc) => {
                                let mut m = (*m_arc).as_standard_layout().to_owned();
                                if idx_vals.len() == 1 {
                                    if let Value::LogicalMatrix(mask) = &idx_vals[0] {
                                        let mut src_idx = 0;
                                        let src_flat: Vec<f64> = match &val {
                                            Value::Matrix(m) => m.iter().copied().collect(),
                                            Value::Scalar(n) => vec![*n],
                                            _ => Vec::new(),
                                        };
                                        for col in 0..m.ncols() {
                                            for row in 0..m.nrows() {
                                                if mask[[row, col]] {
                                                    let fill_val = if src_flat.len() == 1 { src_flat[0] }
                                                                   else { *src_flat.get(src_idx).unwrap_or(&0.0) };
                                                    m[[row, col]] = fill_val;
                                                    src_idx += 1;
                                                }
                                            }
                                        }
                                    } else {
                                        let indices: Vec<usize> = match &idx_vals[0] {
                                            Value::Scalar(i) => vec![*i as usize],
                                            Value::Matrix(mat) => mat.iter().map(|&i| i as usize).collect(),
                                            Value::Colon => (1..=m.len()).collect(),
                                            _ => return Err("Invalid index type".to_string()),
                                        };
                                        let src_vals: Vec<f64> = match &val {
                                            Value::Scalar(v) => vec![*v],
                                            Value::Matrix(src) => src.iter().copied().collect(),
                                            _ => return Err("Cannot assign non-numeric value to matrix".to_string()),
                                        };
                                        for (i, &idx) in indices.iter().enumerate() {
                                            if idx < 1 || idx > m.len() {
                                                return Err(format!("Index out of bounds: {} for matrix of size {}x{}", idx, m.nrows(), m.ncols()));
                                            }
                                            let idx0 = idx - 1;
                                            let row = idx0 % m.nrows();
                                            let col = idx0 / m.nrows();
                                            let fill_val = if src_vals.len() == 1 { src_vals[0] }
                                                           else { *src_vals.get(i).unwrap_or(&0.0) };
                                            m[[row, col]] = fill_val;
                                        }
                                    }
                                } else if idx_vals.len() == 2 {
                                    let rows: Vec<usize> = match &idx_vals[0] {
                                        Value::Scalar(r) => vec![*r as usize],
                                        Value::Matrix(mat) => mat.iter().map(|&r| r as usize).collect(),
                                        Value::Colon => (1..=m.nrows()).collect(),
                                        _ => return Err("Invalid row index".to_string()),
                                    };
                                    let cols: Vec<usize> = match &idx_vals[1] {
                                        Value::Scalar(c) => vec![*c as usize],
                                        Value::Matrix(mat) => mat.iter().map(|&c| c as usize).collect(),
                                        Value::Colon => (1..=m.ncols()).collect(),
                                        _ => return Err("Invalid column index".to_string()),
                                    };
                                    if let Value::Scalar(v) = val {
                                        for &r in &rows {
                                            for &c in &cols {
                                                if r < 1 || r > m.nrows() || c < 1 || c > m.ncols() {
                                                    return Err("Index out of bounds in assignment".to_string());
                                                }
                                                m[[r - 1, c - 1]] = v;
                                            }
                                        }
                                    } else if let Value::Matrix(src) = val {
                                        if src.nrows() != rows.len() || src.ncols() != cols.len() {
                                            return Err("Subscripted assignment dimension mismatch".to_string());
                                        }
                                        for (ri, &r) in rows.iter().enumerate() {
                                            for (ci, &c) in cols.iter().enumerate() {
                                                if r < 1 || r > m.nrows() || c < 1 || c > m.ncols() {
                                                    return Err("Index out of bounds in assignment".to_string());
                                                }
                                                m[[r - 1, c - 1]] = src[[ri, ci]];
                                            }
                                        }
                                    }
                                }
                                self.env.write().unwrap_or_else(|e| e.into_inner()).define(name.clone(), Value::Matrix(Arc::new(m)));
                                return Ok(());
                            }
                            Value::CellArray(v_arc) => {
                                let mut v = (*v_arc).clone();
                                if idx_vals.len() == 1 {
                                    if let Value::Scalar(i) = idx_vals[0] {
                                        let idx = i as usize;
                                        if idx >= 1 && idx <= v.len() {
                                            v[idx - 1] = val;
                                            self.env.write().unwrap_or_else(|e| e.into_inner()).define(name.clone(), Value::CellArray(Arc::new(v)));
                                            return Ok(());
                                        }
                                    }
                                }
                            }
                            _ => {}
                        }
                    }
                }
                return Err(format!("Indexed assignment not fully supported for {:?}", l));
            }
            Expr::PropertyAccess { target, property } => {
                if let Expr::Identifier(struct_name) = &**target {
                    let mut current = self.env.read().unwrap_or_else(|e| e.into_inner()).get(struct_name)
                        .unwrap_or_else(|| Value::Struct(Arc::new(std::collections::HashMap::new())));
                    
                    if let Value::Struct(map) = current {
                        let mut new_map = (*map).clone();
                        new_map.insert(property.clone(), val);
                        self.env.write().unwrap_or_else(|e| e.into_inner()).define(struct_name.clone(), Value::Struct(Arc::new(new_map)));
                        return Ok(());
                    }
                }
                return Err("Property assignment only supported on direct structs".to_string());
            }
            _ => Err(format!("Unsupported assignment LHS: {:?}", l)),
        }
    }

    fn eval_function_call_internal(&mut self, func: &Expr, args: &[Expr], nargout: usize) -> Result<Value, String> {
        let f_val = match func {
            Expr::Identifier(name) => {
                let val_opt = self.env.read().unwrap_or_else(|e| e.into_inner()).get(name);
                if let Some(val) = val_opt {
                    val
                } else if self.find_m_file(name).is_some() {
                    Value::FunctionHandle(name.clone())
                } else {
                    Value::FunctionHandle(name.clone())
                }
            }
            _ => self.eval_expression(func)?,
        };

        let end_vals = match &f_val {
            Value::Matrix(m) => {
                if args.len() == 1 { vec![m.len() as f64] }
                else { vec![m.nrows() as f64, m.ncols() as f64] }
            }
            Value::ComplexMatrix(m) => {
                if args.len() == 1 { vec![m.len() as f64] }
                else { vec![m.nrows() as f64, m.ncols() as f64] }
            }
            Value::CellArray(v) => vec![v.len() as f64],
            Value::String(s) => vec![s.len() as f64],
            _ => Vec::new(),
        };

        let mut arg_vals = Vec::new();
        for (i, a) in args.iter().enumerate() {
            let mut current_ev = None;
            if !end_vals.is_empty() {
                let ev = if end_vals.len() == 1 { end_vals[0] }
                         else if i < end_vals.len() { end_vals[i] }
                         else { *end_vals.last().unwrap() };
                current_ev = Some(ev);
                self.end_stack.push(ev);
            }
            
            let res = self.eval_expression(a);
            if current_ev.is_some() { self.end_stack.pop(); }
            let val = res?;

            // Check for colon expansion {: }
            if let Expr::CellIndexing { args: c_args, .. } = a {
                if c_args.len() == 1 && c_args[0] == Expr::Colon {
                    if let Value::CellArray(v) = val {
                        for item in v.iter() { arg_vals.push(item.clone()); }
                        continue;
                    }
                }
            }
            arg_vals.push(val);
        }

        self.call_function(f_val, arg_vals, nargout)
    }

    fn eval_expression(&mut self, expr: &Expr) -> Result<Value, String> {
        match expr {
            Expr::Number(n) => Ok(Value::Scalar(*n)),
            Expr::Complex(re, im) => Ok(Value::Complex(*re, *im)),
            Expr::String(s) => Ok(Value::String(Arc::new(s.clone()))),
            Expr::End => {
                if let Some(val) = self.end_stack.last() {
                    Ok(Value::Scalar(*val))
                } else {
                    Err("end used outside of indexing context".to_string())
                }
            }
            Expr::Colon => Ok(Value::Colon),
            Expr::Identifier(name) => {
                let val_opt = self.env.read().unwrap_or_else(|e| e.into_inner()).get(name);
                if let Some(val) = val_opt {
                    if let Value::FunctionHandle(ref h_name) = val {
                        let zero_arg_commands = ["clc", "clear", "tic", "toc", "close"];
                        if zero_arg_commands.contains(&h_name.as_str()) {
                            return self.call_function(val, Vec::new(), 1);
                        }
                    }
                    return Ok(val);
                }
                
                let zero_arg_commands = ["clc", "clear", "tic", "toc", "close"];
                if zero_arg_commands.contains(&name.as_str()) {
                    return self.call_function(Value::FunctionHandle(name.clone()), Vec::new(), 1);
                }

                if self.find_m_file(name).is_some() {
                    return Ok(Value::FunctionHandle(name.clone()));
                }
                Err(format!("Undefined variable or function: {}", name))
            }
            Expr::BinaryOp(left, BinaryOperator::ShortAnd, right) => {
                let l = self.eval_expression(left)?;
                if !l.is_truthy() {
                    return Ok(Value::Bool(false));
                }
                let r = self.eval_expression(right)?;
                Ok(Value::Bool(r.is_truthy()))
            }
            Expr::BinaryOp(left, BinaryOperator::ShortOr, right) => {
                let l = self.eval_expression(left)?;
                if l.is_truthy() {
                    return Ok(Value::Bool(true));
                }
                let r = self.eval_expression(right)?;
                Ok(Value::Bool(r.is_truthy()))
            }
            Expr::BinaryOp(left, op, right) => {
                let l = self.eval_expression(left)?;
                let r = self.eval_expression(right)?;
                self.eval_binary_op(l, op, r)
            }
            Expr::UnaryOp(op, inner) => {
                let v = self.eval_expression(inner)?;
                match (op, v) {
                    (UnaryOperator::Plus, v) => Ok(v),
                    (UnaryOperator::Minus, Value::Scalar(n)) => Ok(Value::Scalar(-n)),
                    (UnaryOperator::Minus, Value::Complex(re, im)) => Ok(Value::Complex(-re, -im)),
                    (UnaryOperator::Minus, Value::Matrix(m)) => Ok(Value::Matrix(m.mapv(|x| -x).into())),
                    (UnaryOperator::Minus, Value::ComplexMatrix(m)) => Ok(Value::ComplexMatrix(m.mapv(|x| -x).into())),
                    (UnaryOperator::Not, v) => Ok(Value::Bool(!v.is_truthy())),
                    _ => Err("Invalid unary operation".to_string()),
                }
            }
            Expr::FunctionCall { func, args } => {
                self.eval_function_call_internal(func, args, 1)
            }
            Expr::CellIndexing { target, args } => {
                let val = self.eval_expression(target)?;
                if let Value::CellArray(v) = val {
                    if args.len() == 1 {
                        let idx_val = self.eval_expression(&args[0])?;
                        if let Value::Scalar(i) = idx_val {
                            let idx = i as usize;
                            if idx >= 1 && idx <= v.len() {
                                return Ok(v[idx - 1].clone());
                            }
                            return Err(format!("Cell index out of bounds: {}", idx));
                        }
                    }
                }
                Err("Invalid cell array indexing".to_string())
            }
            Expr::Matrix(rows) => {
                if rows.is_empty() {
                    return Ok(Value::Matrix(Arc::new(Array2::zeros((0, 0)))));
                }

                let mut evaluated_rows = Vec::new();
                for r in rows {
                    let mut row_vals = Vec::new();
                    for expr in r {
                        row_vals.push(self.eval_expression(expr)?);
                    }
                    evaluated_rows.push(row_vals);
                }

                let is_complex = evaluated_rows.iter().any(|r| r.iter().any(|v| matches!(v, Value::Complex(_, _) | Value::ComplexMatrix(_))));
                
                if is_complex {
                    let mut final_rows: Vec<Array2<Complex64>> = Vec::new();
                    for r in evaluated_rows {
                        let mut row_blocks = Vec::new();
                        for v in r {
                            match v {
                                Value::Scalar(n) => row_blocks.push(Array2::from_elem((1, 1), Complex64::new(n, 0.0))),
                                Value::Complex(re, im) => row_blocks.push(Array2::from_elem((1, 1), Complex64::new(re, im))),
                                Value::Matrix(m) => row_blocks.push(m.mapv(|x| Complex64::new(x, 0.0))),
                                Value::ComplexMatrix(m) => row_blocks.push((*m).clone()),
                                _ => return Err("Invalid element in complex matrix".to_string()),
                            }
                        }
                        let views: Vec<_> = row_blocks.iter().map(|m| m.view()).collect();
                        let row_concat = ndarray::concatenate(ndarray::Axis(1), &views).map_err(|e| e.to_string())?;
                        final_rows.push(row_concat);
                    }
                    let views: Vec<_> = final_rows.iter().map(|m| m.view()).collect();
                    let final_concat = ndarray::concatenate(ndarray::Axis(0), &views).map_err(|e| e.to_string())?;
                    Ok(Value::ComplexMatrix(Arc::new(final_concat)))
                } else {
                    let mut final_rows: Vec<Array2<f64>> = Vec::new();
                    for r in evaluated_rows {
                        let mut row_blocks = Vec::new();
                        for v in r {
                            match v {
                                Value::Scalar(n) => row_blocks.push(Array2::from_elem((1, 1), n)),
                                Value::Matrix(m) => row_blocks.push((*m).clone()),
                                Value::Bool(b) => row_blocks.push(Array2::from_elem((1, 1), if b { 1.0 } else { 0.0 })),
                                Value::LogicalMatrix(m) => row_blocks.push(m.mapv(|b| if b { 1.0 } else { 0.0 })),
                                _ => return Err(format!("Invalid element in matrix: {:?}", v)),
                            }
                        }
                        let views: Vec<_> = row_blocks.iter().map(|m| m.view()).collect();
                        let row_concat = ndarray::concatenate(ndarray::Axis(1), &views).map_err(|e| e.to_string())?;
                        final_rows.push(row_concat);
                    }
                    let views: Vec<_> = final_rows.iter().map(|m| m.view()).collect();
                    let final_concat = ndarray::concatenate(ndarray::Axis(0), &views).map_err(|e| e.to_string())?;
                    Ok(Value::Matrix(Arc::new(final_concat)))
                }
            }
            Expr::CellArray(rows) => {
                let mut cells = Vec::new();
                for r in rows {
                    for expr in r {
                        cells.push(self.eval_expression(expr)?);
                    }
                }
                Ok(Value::CellArray(Arc::new(cells)))
            }
            Expr::Transpose(inner) => {
                let v = self.eval_expression(inner)?;
                match v {
                    Value::Matrix(m) => Ok(Value::Matrix(Arc::new(m.t().as_standard_layout().to_owned()))),
                    Value::ComplexMatrix(m) => Ok(Value::ComplexMatrix(Arc::new(m.t().mapv(|c| c.conj()).as_standard_layout().to_owned()))),
                    Value::LogicalMatrix(m) => Ok(Value::LogicalMatrix(Arc::new(m.t().as_standard_layout().to_owned()))),
                    Value::Scalar(n) => Ok(Value::Scalar(n)),
                    Value::Complex(re, im) => Ok(Value::Complex(re, -im)),
                    Value::String(s) => Ok(Value::String(s)),
                    Value::CellArray(c) => Ok(Value::CellArray(c)),
                    Value::Void => Ok(Value::Void),
                    _ => Err("Transpose not implemented for this type".to_string()),
                }
            }
            Expr::ArrayTranspose(inner) => {
                let v = self.eval_expression(inner)?;
                match v {
                    Value::Matrix(m) => Ok(Value::Matrix(Arc::new(m.t().as_standard_layout().to_owned()))),
                    Value::ComplexMatrix(m) => Ok(Value::ComplexMatrix(Arc::new(m.t().as_standard_layout().to_owned()))),
                    Value::LogicalMatrix(m) => Ok(Value::LogicalMatrix(Arc::new(m.t().as_standard_layout().to_owned()))),
                    Value::Scalar(n) => Ok(Value::Scalar(n)),
                    Value::Complex(re, im) => Ok(Value::Complex(re, im)),
                    Value::String(s) => Ok(Value::String(s)),
                    Value::CellArray(c) => Ok(Value::CellArray(c)),
                    Value::Void => Ok(Value::Void),
                    _ => Err("ArrayTranspose not implemented for this type".to_string()),
                }
            }
            Expr::PropertyAccess { target, property } => {
                let val = self.eval_expression(target)?;
                match val {
                    Value::Struct(map) => {
                        if let Some(v) = map.get(property) {
                            Ok(v.clone())
                        } else {
                            Err(format!("Field '{}' not found in struct", property))
                        }
                    }
                    _ => Err("Property access only allowed on structs".to_string()),
                }
            }
            Expr::AnonymousFunc { params, body } => {
                Ok(Value::AnonymousFunction {
                    params: params.clone(),
                    body: Arc::new((**body).clone()),
                })
            }
            Expr::FunctionHandle(name) => Ok(Value::FunctionHandle(name.clone())),
            Expr::KeywordArg(k, v) => {
                let val = self.eval_expression(v)?;
                let mut map = std::collections::HashMap::new();
                map.insert(k.clone(), val);
                Ok(Value::Struct(Arc::new(map)))
            }
            Expr::Ignore => Ok(Value::Void),
        }
    }

    fn eval_binary_op(&mut self, left: Value, op: &BinaryOperator, right: Value) -> Result<Value, String> {
        match (left, op, right) {
            (Value::Scalar(a), op, Value::Scalar(b)) => {
                match op {
                    BinaryOperator::Add | BinaryOperator::DotAdd => Ok(Value::Scalar(a + b)),
                    BinaryOperator::Sub | BinaryOperator::DotSub => Ok(Value::Scalar(a - b)),
                    BinaryOperator::Mul | BinaryOperator::DotMul => Ok(Value::Scalar(a * b)),
                    BinaryOperator::Div | BinaryOperator::DotDiv => {
                        if b == 0.0 {
                            if a == 0.0 { Ok(Value::Scalar(f64::NAN)) }
                            else if a > 0.0 { Ok(Value::Scalar(f64::INFINITY)) }
                            else { Ok(Value::Scalar(f64::NEG_INFINITY)) }
                        } else {
                            Ok(Value::Scalar(a / b))
                        }
                    }
                    BinaryOperator::LDiv | BinaryOperator::DotLDiv => {
                        if a == 0.0 {
                            if b == 0.0 { Ok(Value::Scalar(f64::NAN)) }
                            else if b > 0.0 { Ok(Value::Scalar(f64::INFINITY)) }
                            else { Ok(Value::Scalar(f64::NEG_INFINITY)) }
                        } else {
                            Ok(Value::Scalar(b / a))
                        }
                    }
                    BinaryOperator::Pow | BinaryOperator::DotPow => Ok(Value::Scalar(a.powf(b))),
                    BinaryOperator::Eq => Ok(Value::Bool(a == b)),
                    BinaryOperator::Ne => Ok(Value::Bool(a != b)),
                    BinaryOperator::Lt => Ok(Value::Bool(a < b)),
                    BinaryOperator::Gt => Ok(Value::Bool(a > b)),
                    BinaryOperator::Le => Ok(Value::Bool(a <= b)),
                    BinaryOperator::Ge => Ok(Value::Bool(a >= b)),
                    BinaryOperator::And => Ok(Value::Bool(a != 0.0 && b != 0.0)),
                    BinaryOperator::Or => Ok(Value::Bool(a != 0.0 || b != 0.0)),
                    BinaryOperator::ShortAnd => Ok(Value::Bool(a != 0.0 && b != 0.0)),
                    BinaryOperator::ShortOr => Ok(Value::Bool(a != 0.0 || b != 0.0)),
                }
            }
            (Value::Complex(re1, im1), op, Value::Scalar(b)) => {
                let a = Complex64::new(re1, im1);
                let b_c = Complex64::new(b, 0.0);
                match op {
                    BinaryOperator::Add | BinaryOperator::DotAdd => { let r = a + b_c; Ok(Value::Complex(r.re, r.im)) }
                    BinaryOperator::Sub | BinaryOperator::DotSub => { let r = a - b_c; Ok(Value::Complex(r.re, r.im)) }
                    BinaryOperator::Mul | BinaryOperator::DotMul => { let r = a * b_c; Ok(Value::Complex(r.re, r.im)) }
                    BinaryOperator::Div | BinaryOperator::DotDiv => { let r = a / b_c; Ok(Value::Complex(r.re, r.im)) }
                    _ => Err(format!("Operator {:?} not implemented for Complex/Scalar", op)),
                }
            }
            (Value::Scalar(a), op, Value::Complex(re2, im2)) => {
                let a_c = Complex64::new(a, 0.0);
                let b = Complex64::new(re2, im2);
                match op {
                    BinaryOperator::Add | BinaryOperator::DotAdd => { let r = a_c + b; Ok(Value::Complex(r.re, r.im)) }
                    BinaryOperator::Sub | BinaryOperator::DotSub => { let r = a_c - b; Ok(Value::Complex(r.re, r.im)) }
                    BinaryOperator::Mul | BinaryOperator::DotMul => { let r = a_c * b; Ok(Value::Complex(r.re, r.im)) }
                    BinaryOperator::Div | BinaryOperator::DotDiv => { let r = a_c / b; Ok(Value::Complex(r.re, r.im)) }
                    _ => Err(format!("Operator {:?} not implemented for Scalar/Complex", op)),
                }
            }
            (Value::Complex(re1, im1), op, Value::Complex(re2, im2)) => {
                let a = Complex64::new(re1, im1);
                let b = Complex64::new(re2, im2);
                match op {
                    BinaryOperator::Add | BinaryOperator::DotAdd => { let r = a + b; Ok(Value::Complex(r.re, r.im)) }
                    BinaryOperator::Sub | BinaryOperator::DotSub => { let r = a - b; Ok(Value::Complex(r.re, r.im)) }
                    BinaryOperator::Mul | BinaryOperator::DotMul => { let r = a * b; Ok(Value::Complex(r.re, r.im)) }
                    BinaryOperator::Div | BinaryOperator::DotDiv => { let r = a / b; Ok(Value::Complex(r.re, r.im)) }
                    BinaryOperator::Eq => Ok(Value::Bool(a == b)),
                    BinaryOperator::Ne => Ok(Value::Bool(a != b)),
                    _ => Err(format!("Operator {:?} not implemented for Complex/Complex", op)),
                }
            }
            (Value::Matrix(a), op, Value::Matrix(b)) => {
                match op {
                    BinaryOperator::Add | BinaryOperator::DotAdd => {
                        if a.len() == 1 {
                            let s = a[[0, 0]];
                            return Ok(Value::Matrix(Arc::new(b.mapv(|x| s + x))));
                        }
                        if b.len() == 1 {
                            let s = b[[0, 0]];
                            return Ok(Value::Matrix(Arc::new(a.mapv(|x| x + s))));
                        }
                        if a.dim() != b.dim() {
                            return Err(format!("Matrix dimensions must agree for addition: {:?} vs {:?}", a.dim(), b.dim()));
                        }
                        let res = ndarray::Zip::from(&*a).and(&*b).map_collect(|&x, &y| x + y);
                        Ok(Value::Matrix(Arc::new(res)))
                    }
                    BinaryOperator::Sub | BinaryOperator::DotSub => {
                        if a.len() == 1 {
                            let s = a[[0, 0]];
                            return Ok(Value::Matrix(Arc::new(b.mapv(|x| s - x))));
                        }
                        if b.len() == 1 {
                            let s = b[[0, 0]];
                            return Ok(Value::Matrix(Arc::new(a.mapv(|x| x - s))));
                        }
                        if a.dim() != b.dim() {
                            return Err(format!("Matrix dimensions must agree for subtraction: {:?} vs {:?}", a.dim(), b.dim()));
                        }
                        let res = ndarray::Zip::from(&*a).and(&*b).map_collect(|&x, &y| x - y);
                        Ok(Value::Matrix(Arc::new(res)))
                    }
                    BinaryOperator::Mul => {
                        if a.len() == 1 {
                            let s = a[[0, 0]];
                            return Ok(Value::Matrix(Arc::new(b.mapv(|x| s * x))));
                        }
                        if b.len() == 1 {
                            let s = b[[0, 0]];
                            return Ok(Value::Matrix(Arc::new(a.mapv(|x| x * s))));
                        }
                        if a.ncols() != b.nrows() {
                            return Err(format!("Inner matrix dimensions must agree: {:?} and {:?}", a.dim(), b.dim()));
                        }
                        Ok(Value::Matrix(Arc::new(a.dot(&*b))))
                    }
                    BinaryOperator::DotMul => {
                        if a.len() == 1 {
                            let s = a[[0, 0]];
                            return Ok(Value::Matrix(Arc::new(b.mapv(|x| s * x))));
                        }
                        if b.len() == 1 {
                            let s = b[[0, 0]];
                            return Ok(Value::Matrix(Arc::new(a.mapv(|x| x * s))));
                        }
                        if a.dim() != b.dim() {
                            return Err(format!("Matrix dimensions must agree for .*: {:?} vs {:?}", a.dim(), b.dim()));
                        }
                        let res = ndarray::Zip::from(&*a).and(&*b).map_collect(|&x, &y| x * y);
                        Ok(Value::Matrix(Arc::new(res)))
                    }
                    BinaryOperator::DotDiv => {
                        if b.len() == 1 {
                            let s = b[[0, 0]];
                            return Ok(Value::Matrix(Arc::new(a.mapv(|x| x / s))));
                        }
                        if a.len() == 1 {
                            let s = a[[0, 0]];
                            return Ok(Value::Matrix(Arc::new(b.mapv(|x| s / x))));
                        }
                        if a.dim() != b.dim() {
                            return Err(format!("Matrix dimensions must agree for ./: {:?} vs {:?}", a.dim(), b.dim()));
                        }
                        let res = ndarray::Zip::from(&*a).and(&*b).map_collect(|&x, &y| x / y);
                        Ok(Value::Matrix(Arc::new(res)))
                    }
                    BinaryOperator::Div => {
                        // mrdivide: A / B = A * inv(B)
                        if b.len() == 1 {
                            let s = b[[0, 0]];
                            if s == 0.0 {
                                return Err("Division by zero in matrix division".to_string());
                            }
                            return Ok(Value::Matrix(Arc::new(a.mapv(|x| x / s))));
                        }
                        if b.nrows() == 2 && b.ncols() == 2 {
                            let det = b[[0, 0]] * b[[1, 1]] - b[[0, 1]] * b[[1, 0]];
                            if det == 0.0 {
                                return Err("Matrix is singular to working precision in mrdivide".to_string());
                            }
                            let mut inv_b = Array2::zeros((2, 2));
                            inv_b[[0, 0]] = b[[1, 1]] / det;
                            inv_b[[1, 1]] = b[[0, 0]] / det;
                            inv_b[[0, 1]] = -b[[0, 1]] / det;
                            inv_b[[1, 0]] = -b[[1, 0]] / det;
                            if a.ncols() != 2 {
                                return Err(format!("Matrix dimensions must agree for mrdivide: {:?} vs {:?}", a.dim(), b.dim()));
                            }
                            return Ok(Value::Matrix(Arc::new(a.dot(&inv_b))));
                        }
                        PythonBridge::call_runtime_func("mrdivide", vec![Value::Matrix(a), Value::Matrix(b)], 1).map_err(|e| e.to_string())
                    }
                    BinaryOperator::LDiv | BinaryOperator::DotLDiv => {
                        PythonBridge::call_runtime_func("mldivide", vec![Value::Matrix(a), Value::Matrix(b)], 1).map_err(|e| e.to_string())
                    }
                    BinaryOperator::DotPow => {
                        if b.len() == 1 {
                            let p = b[[0, 0]];
                            return Ok(Value::Matrix(Arc::new(a.mapv(|x| x.powf(p)))));
                        }
                        if a.len() == 1 {
                            let base = a[[0, 0]];
                            return Ok(Value::Matrix(Arc::new(b.mapv(|x| base.powf(x)))));
                        }
                        if a.dim() != b.dim() {
                            return Err(format!("Matrix dimensions must agree for .^: {:?} vs {:?}", a.dim(), b.dim()));
                        }
                        let res = ndarray::Zip::from(&*a).and(&*b).map_collect(|&x, &y| x.powf(y));
                        Ok(Value::Matrix(Arc::new(res)))
                    }
                    BinaryOperator::Eq => {
                        if a.dim() != b.dim() {
                            return Ok(Value::LogicalMatrix(Arc::new(Array2::from_elem(a.raw_dim(), false))));
                        }
                        let res = ndarray::Zip::from(&*a).and(&*b).map_collect(|&x, &y| x == y);
                        Ok(Value::LogicalMatrix(Arc::new(res)))
                    }
                    BinaryOperator::Ne => {
                        if a.dim() != b.dim() {
                            return Ok(Value::LogicalMatrix(Arc::new(Array2::from_elem(a.raw_dim(), true))));
                        }
                        let res = ndarray::Zip::from(&*a).and(&*b).map_collect(|&x, &y| x != y);
                        Ok(Value::LogicalMatrix(Arc::new(res)))
                    }
                    BinaryOperator::Lt => {
                        if a.dim() != b.dim() {
                            return Err(format!("Matrix dimensions must agree: {:?} vs {:?}", a.dim(), b.dim()));
                        }
                        let res = ndarray::Zip::from(&*a).and(&*b).map_collect(|&x, &y| x < y);
                        Ok(Value::LogicalMatrix(Arc::new(res)))
                    }
                    BinaryOperator::Gt => {
                        if a.dim() != b.dim() {
                            return Err(format!("Matrix dimensions must agree: {:?} vs {:?}", a.dim(), b.dim()));
                        }
                        let res = ndarray::Zip::from(&*a).and(&*b).map_collect(|&x, &y| x > y);
                        Ok(Value::LogicalMatrix(Arc::new(res)))
                    }
                    BinaryOperator::Le => {
                        if a.dim() != b.dim() {
                            return Err(format!("Matrix dimensions must agree: {:?} vs {:?}", a.dim(), b.dim()));
                        }
                        let res = ndarray::Zip::from(&*a).and(&*b).map_collect(|&x, &y| x <= y);
                        Ok(Value::LogicalMatrix(Arc::new(res)))
                    }
                    BinaryOperator::Ge => {
                        if a.dim() != b.dim() {
                            return Err(format!("Matrix dimensions must agree: {:?} vs {:?}", a.dim(), b.dim()));
                        }
                        let res = ndarray::Zip::from(&*a).and(&*b).map_collect(|&x, &y| x >= y);
                        Ok(Value::LogicalMatrix(Arc::new(res)))
                    }
                    _ => Err(format!("Operator {:?} not implemented for Matrix/Matrix", op)),
                }
            }
            (Value::Matrix(a), op, Value::Scalar(b)) => {
                match op {
                    BinaryOperator::Add | BinaryOperator::DotAdd => Ok(Value::Matrix(Arc::new(a.mapv(|x| x + b)))),
                    BinaryOperator::Sub | BinaryOperator::DotSub => Ok(Value::Matrix(Arc::new(a.mapv(|x| x - b)))),
                    BinaryOperator::Mul | BinaryOperator::DotMul => Ok(Value::Matrix(Arc::new(a.mapv(|x| x * b)))),
                    BinaryOperator::Div | BinaryOperator::DotDiv => Ok(Value::Matrix(Arc::new(a.mapv(|x| x / b)))),
                    BinaryOperator::DotPow | BinaryOperator::Pow => Ok(Value::Matrix(Arc::new(a.mapv(|x| x.powf(b))))),
                    BinaryOperator::Eq => Ok(Value::LogicalMatrix(Arc::new(a.mapv(|x| x == b)))),
                    BinaryOperator::Ne => Ok(Value::LogicalMatrix(Arc::new(a.mapv(|x| x != b)))),
                    BinaryOperator::Lt => Ok(Value::LogicalMatrix(Arc::new(a.mapv(|x| x < b)))),
                    BinaryOperator::Gt => Ok(Value::LogicalMatrix(Arc::new(a.mapv(|x| x > b)))),
                    BinaryOperator::Le => Ok(Value::LogicalMatrix(Arc::new(a.mapv(|x| x <= b)))),
                    BinaryOperator::Ge => Ok(Value::LogicalMatrix(Arc::new(a.mapv(|x| x >= b)))),
                    _ => Err(format!("Operator {:?} not implemented for Matrix/Scalar", op)),
                }
            }
            (Value::Scalar(a), op, Value::Matrix(b)) => {
                match op {
                    BinaryOperator::Add | BinaryOperator::DotAdd => Ok(Value::Matrix(Arc::new(b.mapv(|x| a + x)))),
                    BinaryOperator::Sub | BinaryOperator::DotSub => Ok(Value::Matrix(Arc::new(b.mapv(|x| a - x)))),
                    BinaryOperator::Mul | BinaryOperator::DotMul => Ok(Value::Matrix(Arc::new(b.mapv(|x| a * x)))),
                    BinaryOperator::Div | BinaryOperator::DotDiv => Ok(Value::Matrix(Arc::new(b.mapv(|x| a / x)))),
                    BinaryOperator::DotPow | BinaryOperator::Pow => Ok(Value::Matrix(Arc::new(b.mapv(|x| a.powf(x))))),
                    BinaryOperator::Eq => Ok(Value::LogicalMatrix(Arc::new(b.mapv(|x| a == x)))),
                    BinaryOperator::Ne => Ok(Value::LogicalMatrix(Arc::new(b.mapv(|x| a != x)))),
                    BinaryOperator::Lt => Ok(Value::LogicalMatrix(Arc::new(b.mapv(|x| a < x)))),
                    BinaryOperator::Gt => Ok(Value::LogicalMatrix(Arc::new(b.mapv(|x| a > x)))),
                    BinaryOperator::Le => Ok(Value::LogicalMatrix(Arc::new(b.mapv(|x| a <= x)))),
                    BinaryOperator::Ge => Ok(Value::LogicalMatrix(Arc::new(b.mapv(|x| a >= x)))),
                    _ => Err(format!("Operator {:?} not implemented for Scalar/Matrix", op)),
                }
            }
            (Value::Bool(a), op, Value::Scalar(b)) => {
                let a_val = if a { 1.0 } else { 0.0 };
                self.eval_binary_op(Value::Scalar(a_val), op, Value::Scalar(b))
            }
            (Value::Scalar(a), op, Value::Bool(b)) => {
                let b_val = if b { 1.0 } else { 0.0 };
                self.eval_binary_op(Value::Scalar(a), op, Value::Scalar(b_val))
            }
            (Value::Matrix(a), op, Value::Bool(b)) => {
                let b_val = if b { 1.0 } else { 0.0 };
                self.eval_binary_op(Value::Matrix(a), op, Value::Scalar(b_val))
            }
            (Value::Bool(a), op, Value::Matrix(b)) => {
                let a_val = if a { 1.0 } else { 0.0 };
                self.eval_binary_op(Value::Scalar(a_val), op, Value::Matrix(b))
            }
            (Value::LogicalMatrix(a), op, Value::LogicalMatrix(b)) => {
                match op {
                    BinaryOperator::And | BinaryOperator::ShortAnd => {
                        if a.dim() != b.dim() {
                            return Err("Logical matrix dimensions must agree".to_string());
                        }
                        let res = ndarray::Zip::from(&*a).and(&*b).map_collect(|&x, &y| x && y);
                        Ok(Value::LogicalMatrix(Arc::new(res)))
                    }
                    BinaryOperator::Or | BinaryOperator::ShortOr => {
                        if a.dim() != b.dim() {
                            return Err("Logical matrix dimensions must agree".to_string());
                        }
                        let res = ndarray::Zip::from(&*a).and(&*b).map_collect(|&x, &y| x || y);
                        Ok(Value::LogicalMatrix(Arc::new(res)))
                    }
                    BinaryOperator::Eq => {
                        let res = ndarray::Zip::from(&*a).and(&*b).map_collect(|&x, &y| x == y);
                        Ok(Value::LogicalMatrix(Arc::new(res)))
                    }
                    BinaryOperator::Ne => {
                        let res = ndarray::Zip::from(&*a).and(&*b).map_collect(|&x, &y| x != y);
                        Ok(Value::LogicalMatrix(Arc::new(res)))
                    }
                    _ => Err(format!("Operator {:?} not implemented for LogicalMatrix", op)),
                }
            }
            (Value::String(a), BinaryOperator::Eq, Value::String(b)) => Ok(Value::Bool(*a == *b)),
            (Value::String(a), BinaryOperator::Ne, Value::String(b)) => Ok(Value::Bool(*a != *b)),
            (l, _, r) => Err(format!("Binary operation {:?} not yet implemented for these types: {:?} and {:?}", op, l, r)),
        }
    }

    pub(crate) fn call_function(&mut self, func: Value, args: Vec<Value>, nargout: usize) -> Result<Value, String> {
        match func {
            Value::Function { name: _, params, returns, body } => {
                let parent_env = self.env.clone();
                let new_env = Arc::new(RwLock::new(Environment::with_parent(parent_env)));
                for (i, p_name) in params.iter().enumerate() {
                    if i < args.len() {
                        new_env.write().unwrap_or_else(|e| e.into_inner()).define(p_name.clone(), args[i].clone());
                    }
                }
                new_env.write().unwrap_or_else(|e| e.into_inner()).define("nargin".to_string(), Value::Scalar(args.len() as f64));
                new_env.write().unwrap_or_else(|e| e.into_inner()).define("nargout".to_string(), Value::Scalar(nargout.max(1) as f64));
                let old_env = std::mem::replace(&mut self.env, new_env);
                
                let body_res = self.eval_block(&body);
                let outcome = match body_res {
                    Ok(out) => out,
                    Err(e) => {
                        self.env = old_env;
                        return Err(e);
                    }
                };
                
                let mut res_vals = Vec::new();
                if returns.len() == 1 && returns[0] == "varargout" {
                    if let Some(Value::CellArray(v)) = self.env.read().unwrap_or_else(|e| e.into_inner()).get("varargout") {
                        res_vals = v.to_vec();
                    }
                } else {
                    for ret_name in &returns {
                        res_vals.push(self.env.read().unwrap_or_else(|e| e.into_inner()).get(ret_name).unwrap_or(Value::Void));
                    }
                }

                self.env = old_env;
                if res_vals.is_empty() {
                    if let EvalOutcome::Return(ret_val) = outcome {
                        if ret_val != Value::Void {
                            return Ok(ret_val);
                        }
                    }
                    Ok(Value::Void)
                } else if res_vals.len() == 1 {
                    Ok(res_vals[0].clone())
                } else {
                    Ok(Value::List(res_vals.into()))
                }
            }
            Value::AnonymousFunction { params, body } => {
                let parent_env = self.env.clone();
                let new_env = Arc::new(RwLock::new(Environment::with_parent(parent_env)));
                for (i, p_name) in params.iter().enumerate() {
                    if i < args.len() {
                        new_env.write().unwrap_or_else(|e| e.into_inner()).define(p_name.clone(), args[i].clone());
                    }
                }
                new_env.write().unwrap_or_else(|e| e.into_inner()).define("nargin".to_string(), Value::Scalar(args.len() as f64));
                new_env.write().unwrap_or_else(|e| e.into_inner()).define("nargout".to_string(), Value::Scalar(1.0));
                let old_env = std::mem::replace(&mut self.env, new_env);
                let res = self.eval_expression(&body);
                self.env = old_env;
                res
            }
            Value::FunctionHandle(name) => {
                match name.as_str() {
                    "disp" => {
                        for a in &args {
                            let s = a.format_disp();
                            self.stdout.push_str(&s);
                            self.stdout.push('\n');
                        }
                        Ok(Value::Void)
                    }
                    "num2str" => {
                        if args.len() == 1 {
                            return Ok(Value::String(args[0].format_disp().into()));
                        }
                        Err("Invalid num2str args".to_string())
                    }
                    "fprintf" => {
                        if !args.is_empty() {
                            if let Value::String(fmt) = &args[0] {
                                let mut res: String = (**fmt).clone();
                                for i in 1..args.len() {
                                    let s = args[i].format_disp();
                                    res = res.replacen("%s", &s, 1);
                                    res = res.replacen("%d", &s, 1);
                                    res = res.replacen("%.2f", &s, 1);
                                    res = res.replacen("%.3f", &s, 1);
                                    res = res.replacen("%.4f", &s, 1);
                                    res = res.replacen("%f", &s, 1);
                                }
                                self.stdout.push_str(&res);
                                return Ok(Value::Void);
                            } else if args.len() >= 2 {
                                return PythonBridge::call_runtime_func("fprintf", args, nargout).map_err(|e| e.to_string());
                            }
                        }
                        Err("Invalid fprintf args".to_string())
                    }
                    "range" => {
                        if args.len() == 2 {
                            if let (Value::Scalar(start), Value::Scalar(stop)) = (&args[0], &args[1]) {
                                let mut v = Vec::new();
                                let mut curr = *start;
                                while curr <= *stop {
                                    v.push(curr);
                                    curr += 1.0;
                                }
                                let len = v.len();
                                return Ok(Value::Matrix(Arc::new(Array2::from_shape_vec((1, len), v).unwrap())));
                            }
                        } else if args.len() == 3 {
                            if let (Value::Scalar(start), Value::Scalar(step), Value::Scalar(stop)) = (&args[0], &args[1], &args[2]) {
                                let mut v = Vec::new();
                                let mut curr = *start;
                                if *step > 0.0 {
                                    while curr <= *stop {
                                        v.push(curr);
                                        curr += *step;
                                    }
                                } else if *step < 0.0 {
                                    while curr >= *stop {
                                        v.push(curr);
                                        curr += *step;
                                    }
                                }
                                let len = v.len();
                                return Ok(Value::Matrix(Arc::new(Array2::from_shape_vec((1, len), v).unwrap())));
                            }
                        }
                        Err("Invalid range args".to_string())
                    }
                    "size" => {
                        if args.len() == 1 {
                            match &args[0] {
                                Value::Matrix(m) => {
                                    if nargout > 1 {
                                        return Ok(Value::List(Arc::new(vec![Value::Scalar(m.nrows() as f64), Value::Scalar(m.ncols() as f64)])));
                                    }
                                    return Ok(Value::Matrix(Arc::new(Array2::from_shape_vec((1, 2), vec![m.nrows() as f64, m.ncols() as f64]).unwrap())));
                                }
                                Value::ComplexMatrix(m) => {
                                    if nargout > 1 {
                                        return Ok(Value::List(Arc::new(vec![Value::Scalar(m.nrows() as f64), Value::Scalar(m.ncols() as f64)])));
                                    }
                                    return Ok(Value::Matrix(Arc::new(Array2::from_shape_vec((1, 2), vec![m.nrows() as f64, m.ncols() as f64]).unwrap())));
                                }
                                Value::LogicalMatrix(m) => {
                                    if nargout > 1 {
                                        return Ok(Value::List(Arc::new(vec![Value::Scalar(m.nrows() as f64), Value::Scalar(m.ncols() as f64)])));
                                    }
                                    return Ok(Value::Matrix(Arc::new(Array2::from_shape_vec((1, 2), vec![m.nrows() as f64, m.ncols() as f64]).unwrap())));
                                }
                                Value::Scalar(_) => {
                                    if nargout > 1 {
                                        return Ok(Value::List(Arc::new(vec![Value::Scalar(1.0), Value::Scalar(1.0)])));
                                    }
                                    return Ok(Value::Matrix(Arc::new(Array2::from_shape_vec((1, 2), vec![1.0, 1.0]).unwrap())));
                                }
                                Value::String(s) => {
                                    if nargout > 1 {
                                        return Ok(Value::List(Arc::new(vec![Value::Scalar(1.0), Value::Scalar(s.len() as f64)])));
                                    }
                                    return Ok(Value::Matrix(Arc::new(Array2::from_shape_vec((1, 2), vec![1.0, s.len() as f64]).unwrap())));
                                }
                                _ => return Ok(Value::Matrix(Arc::new(Array2::from_shape_vec((1, 2), vec![0.0, 0.0]).unwrap()))),
                            }
                        } else if args.len() == 2 {
                            if let Value::Scalar(dim) = &args[1] {
                                let d = *dim as usize;
                                match &args[0] {
                                    Value::Matrix(m) => {
                                        let sz = if d == 1 { m.nrows() } else if d == 2 { m.ncols() } else { 1 };
                                        return Ok(Value::Scalar(sz as f64));
                                    }
                                    Value::ComplexMatrix(m) => {
                                        let sz = if d == 1 { m.nrows() } else if d == 2 { m.ncols() } else { 1 };
                                        return Ok(Value::Scalar(sz as f64));
                                    }
                                    Value::LogicalMatrix(m) => {
                                        let sz = if d == 1 { m.nrows() } else if d == 2 { m.ncols() } else { 1 };
                                        return Ok(Value::Scalar(sz as f64));
                                    }
                                    _ => return Ok(Value::Scalar(1.0)),
                                }
                            }
                        }
                        Err("Invalid size args".to_string())
                    }
                    "length" => {
                        if args.len() == 1 {
                            match &args[0] {
                                Value::Matrix(m) => return Ok(Value::Scalar(m.nrows().max(m.ncols()) as f64)),
                                Value::ComplexMatrix(m) => return Ok(Value::Scalar(m.nrows().max(m.ncols()) as f64)),
                                Value::LogicalMatrix(m) => return Ok(Value::Scalar(m.nrows().max(m.ncols()) as f64)),
                                Value::String(s) => return Ok(Value::Scalar(s.len() as f64)),
                                Value::CellArray(v) => return Ok(Value::Scalar(v.len() as f64)),
                                Value::Scalar(_) => return Ok(Value::Scalar(1.0)),
                                _ => return Ok(Value::Scalar(0.0)),
                            }
                        }
                        Err("Invalid length args".to_string())
                    }
                    "linspace" => {
                        if args.len() == 2 || args.len() == 3 {
                            let n = if args.len() == 3 {
                                match &args[2] {
                                    Value::Scalar(n_val) => *n_val as usize,
                                    _ => 100,
                                }
                            } else {
                                100
                            };
                            if let (Value::Scalar(x1), Value::Scalar(x2)) = (&args[0], &args[1]) {
                                let mut v = Vec::with_capacity(n);
                                if n == 1 {
                                    v.push(*x2);
                                } else if n > 1 {
                                    let step = (x2 - x1) / ((n - 1) as f64);
                                    for i in 0..n {
                                        v.push(x1 + (i as f64) * step);
                                    }
                                }
                                return Ok(Value::Matrix(Arc::new(Array2::from_shape_vec((1, n), v).unwrap())));
                            }
                        }
                        Err("Invalid linspace args".to_string())
                    }
                    "zeros" => {
                        let (rows, cols) = match args.len() {
                            1 => match &args[0] {
                                Value::Scalar(n) => (*n as usize, *n as usize),
                                _ => return Err("Invalid zeros arg".to_string()),
                            },
                            2 => match (&args[0], &args[1]) {
                                (Value::Scalar(r), Value::Scalar(c)) => (*r as usize, *c as usize),
                                _ => return Err("Invalid zeros args".to_string()),
                            },
                            _ => return Err("Invalid zeros args count".to_string()),
                        };
                        Ok(Value::Matrix(Arc::new(Array2::zeros((rows, cols)))))
                    }
                    "ones" => {
                        let (rows, cols) = match args.len() {
                            1 => match &args[0] {
                                Value::Scalar(n) => (*n as usize, *n as usize),
                                _ => return Err("Invalid ones arg".to_string()),
                            },
                            2 => match (&args[0], &args[1]) {
                                (Value::Scalar(r), Value::Scalar(c)) => (*r as usize, *c as usize),
                                _ => return Err("Invalid ones args".to_string()),
                            },
                            _ => return Err("Invalid ones args count".to_string()),
                        };
                        Ok(Value::Matrix(Arc::new(Array2::from_elem((rows, cols), 1.0))))
                    }
                    "eye" => {
                        let (rows, cols) = match args.len() {
                            1 => match &args[0] {
                                Value::Scalar(n) => (*n as usize, *n as usize),
                                _ => return Err("Invalid eye arg".to_string()),
                            },
                            2 => match (&args[0], &args[1]) {
                                (Value::Scalar(r), Value::Scalar(c)) => (*r as usize, *c as usize),
                                _ => return Err("Invalid eye args".to_string()),
                            },
                            _ => return Err("Invalid eye args count".to_string()),
                        };
                        let mut m = Array2::zeros((rows, cols));
                        for i in 0..rows.min(cols) {
                            m[[i, i]] = 1.0;
                        }
                        Ok(Value::Matrix(Arc::new(m)))
                    }
                    "rand" => {
                        use rand::Rng;
                        let (rows, cols) = match args.len() {
                            0 => (1, 1),
                            1 => match &args[0] {
                                Value::Scalar(n) => (*n as usize, *n as usize),
                                _ => return Err("Invalid rand arg".to_string()),
                            },
                            2 => match (&args[0], &args[1]) {
                                (Value::Scalar(r), Value::Scalar(c)) => (*r as usize, *c as usize),
                                _ => return Err("Invalid rand args".to_string()),
                            },
                            _ => return Err("Invalid rand args count".to_string()),
                        };
                        let mut rng = rand::thread_rng();
                        let data: Vec<f64> = (0..rows * cols).map(|_| rng.r#gen::<f64>()).collect();
                        Ok(Value::Matrix(Arc::new(Array2::from_shape_vec((rows, cols), data).unwrap())))
                    }
                    "randn" => {
                        use rand_distr::{Distribution, StandardNormal};
                        let (rows, cols) = match args.len() {
                            0 => (1, 1),
                            1 => match &args[0] {
                                Value::Scalar(n) => (*n as usize, *n as usize),
                                _ => return Err("Invalid randn arg".to_string()),
                            },
                            2 => match (&args[0], &args[1]) {
                                (Value::Scalar(r), Value::Scalar(c)) => (*r as usize, *c as usize),
                                _ => return Err("Invalid randn args".to_string()),
                            },
                            _ => return Err("Invalid randn args count".to_string()),
                        };
                        let mut rng = rand::thread_rng();
                        let data: Vec<f64> = (0..rows * cols).map(|_| StandardNormal.sample(&mut rng)).collect();
                        Ok(Value::Matrix(Arc::new(Array2::from_shape_vec((rows, cols), data).unwrap())))
                    }
                    "plot" => {
                        let mut x_vals = Vec::new();
                        let mut y_vals = Vec::new();
                        if args.len() == 1 {
                            match &args[0] {
                                Value::Matrix(m) => {
                                    y_vals = m.iter().cloned().collect();
                                    x_vals = (1..=y_vals.len()).map(|i| i as f64).collect();
                                }
                                _ => return Err("Invalid plot single argument".to_string()),
                            }
                        } else if args.len() >= 2 {
                            match (&args[0], &args[1]) {
                                (Value::Matrix(x), Value::Matrix(y)) => {
                                    x_vals = x.iter().cloned().collect();
                                    y_vals = y.iter().cloned().collect();
                                }
                                _ => return Err("Plot requires two matrices".to_string()),
                            }
                        }
                        if !x_vals.is_empty() && !y_vals.is_empty() {
                            self.plots.push(PlotData {
                                plot_type: "line".to_string(),
                                x: x_vals,
                                y: y_vals,
                                title: None,
                                xlabel: None,
                                ylabel: None,
                            });
                        }
                        Ok(Value::Void)
                    }
                    "diag" => {
                        if let Some(arg) = args.first() {
                            match arg {
                                Value::Matrix(m) => {
                                    if m.nrows() == 1 || m.ncols() == 1 {
                                        let v: Vec<f64> = m.iter().copied().collect();
                                        return Ok(Value::Matrix(Arc::new(Array2::from_diag(&ndarray::Array1::from_vec(v)))));
                                    } else {
                                        let diag_v: Vec<f64> = m.diag().iter().copied().collect();
                                        let len = diag_v.len();
                                        return Ok(Value::Matrix(Arc::new(Array2::from_shape_vec((len, 1), diag_v).unwrap())));
                                    }
                                }
                                Value::Scalar(n) => {
                                    return Ok(Value::Matrix(Arc::new(Array2::from_elem((1, 1), *n))));
                                }
                                _ => {}
                            }
                        }
                        Ok(Value::Void)
                    }
                    "kron" => {
                        if args.len() == 2 {
                            if let (Value::Matrix(a), Value::Matrix(b)) = (&args[0], &args[1]) {
                                let mut res = Array2::zeros((a.nrows() * b.nrows(), a.ncols() * b.ncols()));
                                for (i, row_a) in a.rows().into_iter().enumerate() {
                                    for (j, &val_a) in row_a.into_iter().enumerate() {
                                        let mut block = res.slice_mut(ndarray::s![
                                            i * b.nrows()..(i + 1) * b.nrows(),
                                            j * b.ncols()..(j + 1) * b.ncols()
                                        ]);
                                        block.assign(&(&**b * val_a));
                                    }
                                }
                                return Ok(Value::Matrix(Arc::new(res)));
                            }
                        }
                        Err("Invalid arguments for kron".to_string())
                    }
                    "eig" => {
                        if let Some(Value::Matrix(m)) = args.first() {
                            if m.nrows() == 2 && m.ncols() == 2 {
                                let tr = m[[0, 0]] + m[[1, 1]];
                                let det = m[[0, 0]] * m[[1, 1]] - m[[0, 1]] * m[[1, 0]];
                                let disc = tr * tr - 4.0 * det;
                                if disc >= 0.0 {
                                    let l1 = (tr + disc.sqrt()) / 2.0;
                                    let l2 = (tr - disc.sqrt()) / 2.0;
                                    if nargout > 1 {
                                        return Ok(Value::List(Arc::new(vec![
                                            Value::Matrix(Arc::new(Array2::eye(2))),
                                            Value::Matrix(Arc::new(Array2::from_diag(&ndarray::array![l1, l2])))
                                        ])));
                                    }
                                    return Ok(Value::Matrix(Arc::new(ndarray::array![[l1], [l2]])));
                                }
                            }
                        }
                        PythonBridge::call_runtime_func("eig", args, nargout).map_err(|e| e.to_string())
                    }
                    "det" => {
                        if let Some(Value::Matrix(m)) = args.first() {
                            if m.nrows() == 1 && m.ncols() == 1 {
                                return Ok(Value::Scalar(m[[0, 0]]));
                            }
                            if m.nrows() == 2 && m.ncols() == 2 {
                                return Ok(Value::Scalar(m[[0, 0]] * m[[1, 1]] - m[[0, 1]] * m[[1, 0]]));
                            }
                        } else if let Some(Value::Scalar(n)) = args.first() {
                            return Ok(Value::Scalar(*n));
                        }
                        PythonBridge::call_runtime_func("det", args, nargout).map_err(|e| e.to_string())
                    }
                    "inv" => {
                        if let Some(Value::Matrix(m)) = args.first() {
                            if m.nrows() == 1 && m.ncols() == 1 {
                                if m[[0, 0]] != 0.0 {
                                    return Ok(Value::Matrix(Arc::new(ndarray::array![[1.0 / m[[0, 0]]]])));
                                } else {
                                    return Err("Matrix is singular".to_string());
                                }
                            }
                            if m.nrows() == 2 && m.ncols() == 2 {
                                let det = m[[0, 0]] * m[[1, 1]] - m[[0, 1]] * m[[1, 0]];
                                if det != 0.0 {
                                    let mut inv_m = Array2::zeros((2, 2));
                                    inv_m[[0, 0]] = m[[1, 1]] / det;
                                    inv_m[[1, 1]] = m[[0, 0]] / det;
                                    inv_m[[0, 1]] = -m[[0, 1]] / det;
                                    inv_m[[1, 0]] = -m[[1, 0]] / det;
                                    return Ok(Value::Matrix(Arc::new(inv_m)));
                                } else {
                                    return Err("Matrix is singular to working precision".to_string());
                                }
                            }
                        } else if let Some(Value::Scalar(n)) = args.first() {
                            if *n != 0.0 {
                                return Ok(Value::Scalar(1.0 / n));
                            } else {
                                return Err("Division by zero in inv".to_string());
                            }
                        }
                        PythonBridge::call_runtime_func("inv", args, nargout).map_err(|e| e.to_string())
                    }
                    "prod" => {
                        if let Some(arg) = args.first() {
                            match arg {
                                Value::Scalar(n) => return Ok(Value::Scalar(*n)),
                                Value::Matrix(m) => return Ok(Value::Scalar(m.iter().copied().product())),
                                _ => return Ok(Value::Scalar(1.0)),
                            }
                        }
                        Ok(Value::Scalar(1.0))
                    }
                    "all" => {
                        if let Some(arg) = args.first() {
                            match arg {
                                Value::Scalar(n) => return Ok(Value::Bool(*n != 0.0 && !n.is_nan())),
                                Value::Matrix(m) => return Ok(Value::Bool(m.iter().all(|&x| x != 0.0 && !x.is_nan()))),
                                Value::LogicalMatrix(m) => return Ok(Value::Bool(m.iter().all(|&x| x))),
                                _ => return Ok(Value::Bool(true)),
                            }
                        }
                        Ok(Value::Bool(true))
                    }
                    "any" => {
                        if let Some(arg) = args.first() {
                            match arg {
                                Value::Scalar(n) => return Ok(Value::Bool(*n != 0.0 && !n.is_nan())),
                                Value::Matrix(m) => return Ok(Value::Bool(m.iter().any(|&x| x != 0.0 && !x.is_nan()))),
                                Value::LogicalMatrix(m) => return Ok(Value::Bool(m.iter().any(|&x| x))),
                                _ => return Ok(Value::Bool(false)),
                            }
                        }
                        Ok(Value::Bool(false))
                    }
                    "sum" => {
                        if let Some(Value::Matrix(m)) = args.first() {
                            return Ok(Value::Scalar(m.iter().sum()));
                        }
                        if let Some(Value::Scalar(n)) = args.first() {
                            return Ok(Value::Scalar(*n));
                        }
                        Ok(Value::Scalar(0.0))
                    }
                    "mean" => {
                        if let Some(Value::Matrix(m)) = args.first() {
                            let sum: f64 = m.iter().sum();
                            return Ok(Value::Scalar(sum / m.len() as f64));
                        }
                        if let Some(Value::Scalar(n)) = args.first() {
                            return Ok(Value::Scalar(*n));
                        }
                        Ok(Value::Scalar(0.0))
                    }
                    "min" => {
                        if let Some(Value::Matrix(m)) = args.first() {
                            let mut min_val = f64::INFINITY;
                            let mut min_idx = 0;
                            for (i, &val) in m.iter().enumerate() {
                                if val < min_val {
                                    min_val = val;
                                    min_idx = i + 1;
                                }
                            }
                            if nargout > 1 {
                                return Ok(Value::List(Arc::new(vec![Value::Scalar(min_val), Value::Scalar(min_idx as f64)])));
                            }
                            return Ok(Value::Scalar(min_val));
                        }
                        if let Some(Value::Scalar(n)) = args.first() {
                            return Ok(Value::Scalar(*n));
                        }
                        Ok(Value::Scalar(0.0))
                    }
                    "max" => {
                        if let Some(Value::Matrix(m)) = args.first() {
                            let mut max_val = f64::NEG_INFINITY;
                            let mut max_idx = 0;
                            for (i, &val) in m.iter().enumerate() {
                                if val > max_val {
                                    max_val = val;
                                    max_idx = i + 1;
                                }
                            }
                            if nargout > 1 {
                                return Ok(Value::List(Arc::new(vec![Value::Scalar(max_val), Value::Scalar(max_idx as f64)])));
                            }
                            return Ok(Value::Scalar(max_val));
                        }
                        if let Some(Value::Scalar(n)) = args.first() {
                            return Ok(Value::Scalar(*n));
                        }
                        Ok(Value::Scalar(0.0))
                    }
                    "round" => {
                        if let Some(Value::Scalar(n)) = args.first() {
                            return Ok(Value::Scalar(n.round()));
                        }
                        if let Some(Value::Matrix(m)) = args.first() {
                            return Ok(Value::Matrix(Arc::new(m.mapv(|x| x.round()))));
                        }
                        PythonBridge::call_runtime_func("round", args, nargout).map_err(|e| e.to_string())
                    }
                    "floor" => {
                        if let Some(Value::Scalar(n)) = args.first() {
                            return Ok(Value::Scalar(n.floor()));
                        }
                        if let Some(Value::Matrix(m)) = args.first() {
                            return Ok(Value::Matrix(Arc::new(m.mapv(|x| x.floor()))));
                        }
                        PythonBridge::call_runtime_func("floor", args, nargout).map_err(|e| e.to_string())
                    }
                    "ceil" => {
                        if let Some(Value::Scalar(n)) = args.first() {
                            return Ok(Value::Scalar(n.ceil()));
                        }
                        if let Some(Value::Matrix(m)) = args.first() {
                            return Ok(Value::Matrix(Arc::new(m.mapv(|x| x.ceil()))));
                        }
                        PythonBridge::call_runtime_func("ceil", args, nargout).map_err(|e| e.to_string())
                    }
                    "exp" => {
                        if let Some(Value::Scalar(n)) = args.first() {
                            return Ok(Value::Scalar(n.exp()));
                        }
                        if let Some(Value::Matrix(m)) = args.first() {
                            return Ok(Value::Matrix(Arc::new(m.mapv(|x| x.exp()))));
                        }
                        PythonBridge::call_runtime_func("exp", args, nargout).map_err(|e| e.to_string())
                    }
                    "sin" => {
                        if let Some(Value::Scalar(n)) = args.first() {
                            return Ok(Value::Scalar(n.sin()));
                        }
                        if let Some(Value::Matrix(m)) = args.first() {
                            return Ok(Value::Matrix(Arc::new(m.mapv(|x| x.sin()))));
                        }
                        PythonBridge::call_runtime_func("sin", args, nargout).map_err(|e| e.to_string())
                    }
                    "cos" => {
                        if let Some(Value::Scalar(n)) = args.first() {
                            return Ok(Value::Scalar(n.cos()));
                        }
                        if let Some(Value::Matrix(m)) = args.first() {
                            return Ok(Value::Matrix(Arc::new(m.mapv(|x| x.cos()))));
                        }
                        PythonBridge::call_runtime_func("cos", args, nargout).map_err(|e| e.to_string())
                    }
                    "tan" => {
                        if let Some(Value::Scalar(n)) = args.first() {
                            return Ok(Value::Scalar(n.tan()));
                        }
                        if let Some(Value::Matrix(m)) = args.first() {
                            return Ok(Value::Matrix(Arc::new(m.mapv(|x| x.tan()))));
                        }
                        PythonBridge::call_runtime_func("tan", args, nargout).map_err(|e| e.to_string())
                    }
                    "sqrt" => {
                        if let Some(Value::Scalar(n)) = args.first() {
                            return Ok(Value::Scalar(n.sqrt()));
                        }
                        if let Some(Value::Matrix(m)) = args.first() {
                            return Ok(Value::Matrix(Arc::new(m.mapv(|x| x.sqrt()))));
                        }
                        PythonBridge::call_runtime_func("sqrt", args, nargout).map_err(|e| e.to_string())
                    }
                    "abs" => {
                        if let Some(Value::Scalar(n)) = args.first() {
                            return Ok(Value::Scalar(n.abs()));
                        }
                        if let Some(Value::Matrix(m)) = args.first() {
                            return Ok(Value::Matrix(Arc::new(m.mapv(|x| x.abs()))));
                        }
                        PythonBridge::call_runtime_func("abs", args, nargout).map_err(|e| e.to_string())
                    }
                    "sign" => {
                        if let Some(Value::Scalar(n)) = args.first() {
                            return Ok(Value::Scalar(n.signum()));
                        }
                        if let Some(Value::Matrix(m)) = args.first() {
                            return Ok(Value::Matrix(Arc::new(m.mapv(|x| x.signum()))));
                        }
                        PythonBridge::call_runtime_func("sign", args, nargout).map_err(|e| e.to_string())
                    }
                    "real" => {
                        if let Some(arg) = args.first() {
                            match arg {
                                Value::Scalar(n) => return Ok(Value::Scalar(*n)),
                                Value::Complex(re, _) => return Ok(Value::Scalar(*re)),
                                Value::Matrix(m) => return Ok(Value::Matrix(m.clone())),
                                Value::ComplexMatrix(m) => return Ok(Value::Matrix(Arc::new(m.mapv(|x| x.re)))),
                                _ => {}
                            }
                        }
                        PythonBridge::call_runtime_func("real", args, nargout).map_err(|e| e.to_string())
                    }
                    "imag" => {
                        if let Some(arg) = args.first() {
                            match arg {
                                Value::Scalar(_) => return Ok(Value::Scalar(0.0)),
                                Value::Complex(_, im) => return Ok(Value::Scalar(*im)),
                                Value::Matrix(m) => return Ok(Value::Matrix(Arc::new(Array2::zeros(m.raw_dim())))),
                                Value::ComplexMatrix(m) => return Ok(Value::Matrix(Arc::new(m.mapv(|x| x.im)))),
                                _ => {}
                            }
                        }
                        PythonBridge::call_runtime_func("imag", args, nargout).map_err(|e| e.to_string())
                    }
                    "ischar" => Ok(Value::Bool(matches!(args.first(), Some(Value::String(_))))),
                    "iscell" => Ok(Value::Bool(matches!(args.first(), Some(Value::CellArray(_))))),
                    "isnumeric" => Ok(Value::Bool(matches!(args.first(), Some(Value::Scalar(_) | Value::Matrix(_) | Value::Complex(_, _) | Value::ComplexMatrix(_))))),
                    "isempty" => {
                        if let Some(arg) = args.first() {
                            match arg {
                                Value::Matrix(m) => Ok(Value::Bool(m.is_empty())),
                                Value::ComplexMatrix(m) => Ok(Value::Bool(m.is_empty())),
                                Value::LogicalMatrix(m) => Ok(Value::Bool(m.is_empty())),
                                Value::CellArray(v) => Ok(Value::Bool(v.is_empty())),
                                Value::String(s) => Ok(Value::Bool(s.is_empty())),
                                Value::Void => Ok(Value::Bool(true)),
                                _ => Ok(Value::Bool(false)),
                            }
                        } else {
                            Ok(Value::Bool(true))
                        }
                    }
                    "clc" => {
                        self.stdout.clear();
                        Ok(Value::Void)
                    }
                    "clear" => {
                        let mut keys_to_remove = Vec::new();
                        for (k, v) in self.env.read().unwrap_or_else(|e| e.into_inner()).vars.iter() {
                            if !matches!(v, Value::Function { .. }) && !matches!(v, Value::FunctionHandle(_)) {
                                keys_to_remove.push(k.clone());
                            }
                        }
                        let mut env = self.env.write().unwrap_or_else(|e| e.into_inner());
                        for k in keys_to_remove {
                            env.vars.remove(&k);
                        }
                        Ok(Value::Void)
                    }
                    "close" => {
                        let _ = PythonBridge::call_runtime_func("close", args, nargout);
                        Ok(Value::Void)
                    }
                    "tic" => {
                        self.tic_time = Some(TimePoint::now());
                        Ok(Value::Void)
                    }
                    "toc" => {
                        if let Some(start) = self.tic_time {
                            let elapsed = start.elapsed_secs();
                            let msg = format!("Elapsed time is {:.6} seconds.\n", elapsed);
                            self.stdout.push_str(&msg);
                            return Ok(Value::Scalar(elapsed));
                        }
                        Ok(Value::Void)
                    }
                    "pause" => {
                        #[cfg(not(target_arch = "wasm32"))]
                        {
                            if args.len() == 1 {
                                if let Value::Scalar(n) = args[0] {
                                    if n > 0.0 {
                                        std::thread::sleep(std::time::Duration::from_secs_f64(n));
                                    }
                                }
                            }
                        }
                        Ok(Value::Void)
                    }
                    "hold" | "grid" | "title" | "xlabel" | "ylabel" | "legend" | "subplot" |
                    "axis" | "xlim" | "ylim" | "figure" => Ok(Value::Void),
                    _ => {
                        if let Some(path) = self.find_m_file(&name) {
                            let content = fs::read_to_string(path).map_err(|e| e.to_string())?;
                            let program = crate::parser::parse_unilab(&content).map_err(|e| e.to_string())?;
                            if let Some(Stmt::FunctionDef { name: _, params, returns, body }) = program.statements.first() {
                                let parent_env = self.env.clone();
                                let new_env = Arc::new(RwLock::new(Environment::with_parent(parent_env)));
                                for (i, p_name) in params.iter().enumerate() {
                                    if i < args.len() {
                                        new_env.write().unwrap_or_else(|e| e.into_inner()).define(p_name.clone(), args[i].clone());
                                    }
                                }
                                new_env.write().unwrap_or_else(|e| e.into_inner()).define("nargin".to_string(), Value::Scalar(args.len() as f64));
                                new_env.write().unwrap_or_else(|e| e.into_inner()).define("nargout".to_string(), Value::Scalar(nargout.max(1) as f64));
                                new_env.write().unwrap_or_else(|e| e.into_inner()).define("varargin".to_string(), Value::CellArray(args.clone().into()));
                                let old_env = std::mem::replace(&mut self.env, new_env);
                                
                                let body_res = self.eval_block(body);
                                let _outcome = match body_res {
                                    Ok(out) => out,
                                    Err(e) => {
                                        self.env = old_env;
                                        return Err(e);
                                    }
                                };
                                
                                let mut res_vals = Vec::new();
                                if returns.len() == 1 && returns[0] == "varargout" {
                                    if let Some(Value::CellArray(v)) = self.env.read().unwrap_or_else(|e| e.into_inner()).get("varargout") {
                                        res_vals = v.to_vec();
                                    }
                                } else {
                                    let limit = nargout.max(1);
                                    for (i, ret_name) in returns.iter().enumerate() {
                                        if i < limit {
                                            res_vals.push(self.env.read().unwrap_or_else(|e| e.into_inner()).get(ret_name).unwrap_or(Value::Void));
                                        }
                                    }
                                }

                                self.env = old_env;
                                if res_vals.is_empty() {
                                    return Ok(Value::Void);
                                } else if res_vals.len() == 1 {
                                    return Ok(res_vals[0].clone());
                                } else {
                                    return Ok(Value::List(res_vals.into()));
                                }
                            } else {
                                return self.eval_program(&program);
                            }
                        }
                        match PythonBridge::call_runtime_func(&name, args, nargout) {
                            Ok(val) => Ok(val),
                            Err(_) => Err(format!("Built-in function {} not implemented in Rust or Python", name)),
                        }
                    }
                }
            }
            Value::Matrix(m) => {
                let mut res_data = Vec::new();
                if args.len() == 1 {
                    match &args[0] {
                        Value::Scalar(i) => {
                            let idx = *i as isize;
                            let len = m.len() as isize;
                            if idx < 1 || idx > len {
                                return Err(format!("Index out of bounds: {} for matrix of size {}x{}", idx, m.nrows(), m.ncols()));
                            }
                            let idx0 = (idx - 1) as usize;
                            let row = idx0 % m.nrows();
                            let col = idx0 / m.nrows();
                            return Ok(Value::Scalar(m[[row, col]]));
                        }
                        Value::Matrix(indices) => {
                            let len = m.len() as isize;
                            for &idx_val in indices.iter() {
                                let idx = idx_val as isize;
                                if idx < 1 || idx > len {
                                    return Err(format!("Index out of bounds: {} for matrix of size {}x{}", idx, m.nrows(), m.ncols()));
                                }
                                let idx0 = (idx - 1) as usize;
                                let row = idx0 % m.nrows();
                                let col = idx0 / m.nrows();
                                res_data.push(m[[row, col]]);
                            }
                            if indices.len() == 1 {
                                return Ok(Value::Scalar(res_data[0]));
                            }
                            let shape = if m.nrows() == 1 {
                                (1, indices.len())
                            } else if m.ncols() == 1 {
                                (indices.len(), 1)
                            } else {
                                (indices.nrows(), indices.ncols())
                            };
                            return Ok(Value::Matrix(Arc::new(Array2::from_shape_vec(shape, res_data).map_err(|e| e.to_string())?)));
                        }
                        Value::LogicalMatrix(mask) => {
                            if mask.nrows() != m.nrows() || mask.ncols() != m.ncols() {
                                return Err(format!("Logical mask dimension mismatch: {:?} vs {:?}", mask.dim(), m.dim()));
                            }
                            for col in 0..m.ncols() {
                                for row in 0..m.nrows() {
                                    if mask[[row, col]] {
                                        res_data.push(m[[row, col]]);
                                    }
                                }
                            }
                            let len = res_data.len();
                            return Ok(Value::Matrix(Arc::new(Array2::from_shape_vec((len, 1), res_data).map_err(|e| e.to_string())?)));
                        }
                        Value::Colon => {
                            for col in 0..m.ncols() {
                                for row in 0..m.nrows() {
                                    res_data.push(m[[row, col]]);
                                }
                            }
                            return Ok(Value::Matrix(Arc::new(Array2::from_shape_vec((m.len(), 1), res_data).map_err(|e| e.to_string())?)));
                        }
                        _ => return Err("Invalid index type".to_string()),
                    }
                } else if args.len() == 2 {
                    let rows_idx: Vec<usize> = match &args[0] {
                        Value::Scalar(r) => {
                            let ri = *r as isize;
                            if ri < 1 || ri > m.nrows() as isize {
                                return Err(format!("Row index out of bounds: {}", ri));
                            }
                            vec![(ri - 1) as usize]
                        }
                        Value::Matrix(mat) => {
                            let mut v = Vec::new();
                            for &r in mat.iter() {
                                let ri = r as isize;
                                if ri < 1 || ri > m.nrows() as isize {
                                    return Err(format!("Row index out of bounds: {}", ri));
                                }
                                v.push((ri - 1) as usize);
                            }
                            v
                        }
                        Value::Colon => (0..m.nrows()).collect(),
                        _ => return Err("Invalid row index".to_string()),
                    };

                    let cols_idx: Vec<usize> = match &args[1] {
                        Value::Scalar(c) => {
                            let ci = *c as isize;
                            if ci < 1 || ci > m.ncols() as isize {
                                return Err(format!("Column index out of bounds: {}", ci));
                            }
                            vec![(ci - 1) as usize]
                        }
                        Value::Matrix(mat) => {
                            let mut v = Vec::new();
                            for &c in mat.iter() {
                                let ci = c as isize;
                                if ci < 1 || ci > m.ncols() as isize {
                                    return Err(format!("Column index out of bounds: {}", ci));
                                }
                                v.push((ci - 1) as usize);
                            }
                            v
                        }
                        Value::Colon => (0..m.ncols()).collect(),
                        _ => return Err("Invalid column index".to_string()),
                    };

                    if rows_idx.len() == 1 && cols_idx.len() == 1 {
                        return Ok(Value::Scalar(m[[rows_idx[0], cols_idx[0]]]));
                    }

                    for &ri in &rows_idx {
                        for &ci in &cols_idx {
                            res_data.push(m[[ri, ci]]);
                        }
                    }
                    return Ok(Value::Matrix(Arc::new(Array2::from_shape_vec((rows_idx.len(), cols_idx.len()), res_data).map_err(|e| e.to_string())?)));
                }
                Err("Invalid matrix indexing".to_string())
            }
            Value::ComplexMatrix(m) => {
                let mut res_data = Vec::new();
                if args.len() == 1 {
                    match &args[0] {
                        Value::Scalar(i) => {
                            let idx = *i as isize;
                            let len = m.len() as isize;
                            if idx < 1 || idx > len {
                                return Err(format!("Index out of bounds: {} for matrix of size {}x{}", idx, m.nrows(), m.ncols()));
                            }
                            let idx0 = (idx - 1) as usize;
                            let row = idx0 % m.nrows();
                            let col = idx0 / m.nrows();
                            let res = m[[row, col]];
                            return Ok(Value::Complex(res.re, res.im));
                        }
                        Value::Matrix(indices) => {
                            let len = m.len() as isize;
                            for &idx_val in indices.iter() {
                                let idx = idx_val as isize;
                                if idx < 1 || idx > len {
                                    return Err(format!("Index out of bounds: {} for matrix of size {}x{}", idx, m.nrows(), m.ncols()));
                                }
                                let idx0 = (idx - 1) as usize;
                                let row = idx0 % m.nrows();
                                let col = idx0 / m.nrows();
                                res_data.push(m[[row, col]]);
                            }
                            if indices.len() == 1 {
                                let res = res_data[0];
                                return Ok(Value::Complex(res.re, res.im));
                            }
                            let shape = if m.nrows() == 1 {
                                (1, indices.len())
                            } else if m.ncols() == 1 {
                                (indices.len(), 1)
                            } else {
                                (indices.nrows(), indices.ncols())
                            };
                            return Ok(Value::ComplexMatrix(Arc::new(Array2::from_shape_vec(shape, res_data).map_err(|e| e.to_string())?)));
                        }
                        Value::LogicalMatrix(mask) => {
                            for col in 0..m.ncols() {
                                for row in 0..m.nrows() {
                                    if mask[[row, col]] {
                                        res_data.push(m[[row, col]]);
                                    }
                                }
                            }
                            let len = res_data.len();
                            return Ok(Value::ComplexMatrix(Arc::new(Array2::from_shape_vec((len, 1), res_data).map_err(|e| e.to_string())?)));
                        }
                        Value::Colon => {
                            for col in 0..m.ncols() {
                                for row in 0..m.nrows() {
                                    res_data.push(m[[row, col]]);
                                }
                            }
                            return Ok(Value::ComplexMatrix(Arc::new(Array2::from_shape_vec((m.len(), 1), res_data).map_err(|e| e.to_string())?)));
                        }
                        _ => return Err("Invalid index type".to_string()),
                    }
                } else if args.len() == 2 {
                    let rows_idx: Vec<usize> = match &args[0] {
                        Value::Scalar(r) => {
                            let ri = *r as isize;
                            if ri < 1 || ri > m.nrows() as isize {
                                return Err(format!("Row index out of bounds: {}", ri));
                            }
                            vec![(ri - 1) as usize]
                        }
                        Value::Matrix(mat) => {
                            let mut v = Vec::new();
                            for &r in mat.iter() {
                                let ri = r as isize;
                                if ri < 1 || ri > m.nrows() as isize {
                                    return Err(format!("Row index out of bounds: {}", ri));
                                }
                                v.push((ri - 1) as usize);
                            }
                            v
                        }
                        Value::Colon => (0..m.nrows()).collect(),
                        _ => return Err("Invalid row index".to_string()),
                    };

                    let cols_idx: Vec<usize> = match &args[1] {
                        Value::Scalar(c) => {
                            let ci = *c as isize;
                            if ci < 1 || ci > m.ncols() as isize {
                                return Err(format!("Column index out of bounds: {}", ci));
                            }
                            vec![(ci - 1) as usize]
                        }
                        Value::Matrix(mat) => {
                            let mut v = Vec::new();
                            for &c in mat.iter() {
                                let ci = c as isize;
                                if ci < 1 || ci > m.ncols() as isize {
                                    return Err(format!("Column index out of bounds: {}", ci));
                                }
                                v.push((ci - 1) as usize);
                            }
                            v
                        }
                        Value::Colon => (0..m.ncols()).collect(),
                        _ => return Err("Invalid column index".to_string()),
                    };

                    if rows_idx.len() == 1 && cols_idx.len() == 1 {
                        let res = m[[rows_idx[0], cols_idx[0]]];
                        return Ok(Value::Complex(res.re, res.im));
                    }

                    for &ri in &rows_idx {
                        for &ci in &cols_idx {
                            res_data.push(m[[ri, ci]]);
                        }
                    }
                    return Ok(Value::ComplexMatrix(Arc::new(Array2::from_shape_vec((rows_idx.len(), cols_idx.len()), res_data).map_err(|e| e.to_string())?)));
                }
                Err("Invalid complex matrix indexing".to_string())
            }
            Value::CellArray(v) => {
                if args.len() == 1 {
                    match &args[0] {
                        Value::Scalar(i) => {
                            let idx = *i as isize;
                            if idx >= 1 && idx <= v.len() as isize {
                                return Ok(v[(idx - 1) as usize].clone());
                            }
                            return Err(format!("Cell index out of bounds: {}", idx));
                        }
                        Value::Matrix(indices) => {
                            let mut res = Vec::new();
                            for &idx_val in indices.iter() {
                                let idx = idx_val as isize;
                                if idx >= 1 && idx <= v.len() as isize {
                                    res.push(v[(idx - 1) as usize].clone());
                                } else {
                                    return Err(format!("Cell index out of bounds: {}", idx));
                                }
                            }
                            return Ok(Value::CellArray(Arc::new(res)));
                        }
                        Value::Colon => return Ok(Value::CellArray(v.clone())),
                        _ => {}
                    }
                }
                Err("Invalid cell array indexing".to_string())
            }
            _ => {
                if args.is_empty() {
                    Ok(func)
                } else {
                    Err(format!("Cannot call {:?}", func))
                }
            }
        }
    }

    fn find_m_file(&self, name: &str) -> Option<PathBuf> {
        for path in &self.search_paths {
            let mut file_path = path.clone();
            file_path.push(format!("{}.m", name));
            if file_path.exists() {
                return Some(file_path);
            }
        }
        None
    }
}
