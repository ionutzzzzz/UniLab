use crate::parser::ast::*;
use crate::runtime::value::Value;
use crate::runtime::env::Environment;
use std::sync::{Arc, RwLock};
use ndarray::Array2;
use std::path::PathBuf;
use std::fs;
use crate::api::PlotData;
use crate::runtime::bridge::PythonBridge;
use num_complex::Complex64;
use std::time::Instant;

pub struct Evaluator {
    pub env: Arc<RwLock<Environment>>,
    pub search_paths: Vec<PathBuf>,
    pub plots: Vec<PlotData>,
    pub tic_time: Option<Instant>,
    pub end_stack: Vec<f64>,
}

impl Evaluator {
    pub fn new() -> Self {
        eprintln!("Creating new Evaluator");
        let mut builtins_env = Environment::new();

        // Constants
        builtins_env.define("pi".to_string(), Value::Scalar(std::f64::consts::PI));
        builtins_env.define("eps".to_string(), Value::Scalar(f64::EPSILON));
        builtins_env.define("i".to_string(), Value::Complex(0.0, 1.0));
        builtins_env.define("j".to_string(), Value::Complex(0.0, 1.0));
        builtins_env.define("inf".to_string(), Value::Scalar(f64::INFINITY));
        builtins_env.define("Inf".to_string(), Value::Scalar(f64::INFINITY));
        builtins_env.define("nan".to_string(), Value::Scalar(f64::NAN));
        builtins_env.define("NaN".to_string(), Value::Scalar(f64::NAN));
        builtins_env.define("true".to_string(), Value::Bool(true));
        builtins_env.define("false".to_string(), Value::Bool(false));

        // Built-ins
        let builtins = vec![
            "disp", "range", "size", "plot", "simulate", "linspace", "zeros", "ones", "eye",
            "rand", "randn", "randperm", "exp", "sin", "cos", "tan", "tanh", "sqrt", "abs", "log", "log10",
            "sum", "mean", "std", "var", "min", "max", "round", "floor", "ceil",
            "struct", "hold", "grid", "title", "xlabel", "ylabel", "legend", "subplot",
            "axis", "xlim", "ylim", "imagesc", "colorbar", "colormap", "factorial",
            "clc", "close", "tic", "toc", "pause", "find", "length", "mode", "reshape", "unique",
            "figure", "gcf", "gca", "clf", "cla", "fprintf", "sprintf", "num2str",
            "deg2rad", "rad2deg", "trapz", "inv", "eig", "diag", "norm", "det",
            "fopen", "fread", "fclose", "fwrite", "mod", "rem", "meshgrid",
            "real", "imag", "sort", "sign", "fft", "ifft",
            "sinh", "cosh", "tanh", "asinh", "acosh", "atanh",
            "ischar", "iscell", "isnumeric", "strcmp", "isequal",
            "argmin", "argmax", "isempty",
        ];

        for name in builtins {
            builtins_env.define(name.to_string(), Value::FunctionHandle(name.to_string()));
        }
        
        let env = Environment::with_parent(Arc::new(RwLock::new(builtins_env)));

        let mut search_paths = vec![PathBuf::from(".")];
        
        // Add stdlib libraries to search path
        let stdlib_path = PathBuf::from("stdlib/libraries");
        if stdlib_path.exists() {
            if let Ok(entries) = fs::read_dir(stdlib_path) {
                for entry in entries.flatten() {
                    if entry.path().is_dir() {
                        search_paths.push(entry.path());
                    }
                }
            }
        } else {
            // Try relative to backend
            let stdlib_path = PathBuf::from("backend/stdlib/libraries");
            if stdlib_path.exists() {
                if let Ok(entries) = fs::read_dir(stdlib_path) {
                    for entry in entries.flatten() {
                        if entry.path().is_dir() {
                            search_paths.push(entry.path());
                        }
                    }
                }
            }
        }

        Self {
            env: Arc::new(RwLock::new(env)),
            search_paths,
            plots: Vec::new(),
            tic_time: None,
            end_stack: Vec::new(),
        }
    }

    pub fn eval_program(&mut self, program: &Program) -> Result<Value, String> {
        // Hoist all local functions first
        for stmt in &program.statements {
            if let Stmt::FunctionDef { name, params, returns, body } = stmt {
                let func = Value::Function {
                    name: name.clone(),
                    params: params.clone(),
                    returns: returns.clone(),
                    body: body.clone(),
                };
                self.env.write().unwrap().define(name.clone(), func);
            }
        }

        let mut last_val = Value::Void;
        for stmt in &program.statements {
            // Skip function definitions since we already hoisted them
            if let Stmt::FunctionDef { .. } = stmt {
                continue;
            }
            last_val = self.eval_statement(stmt)?;
        }
        Ok(last_val)
    }

    fn eval_statement(&mut self, stmt: &Stmt) -> Result<Value, String> {
        eprintln!("Evaluating statement: {:?}", stmt);
        match stmt {
            Stmt::Expression(expr) => {
                let val = self.eval_expression(expr)?;
                // Function handles without arguments are called if they are built-ins like clc
                if let Value::FunctionHandle(name) = &val {
                    let builtins_requiring_no_args = vec!["clc", "tic", "toc", "clf", "cla", "gcf", "gca", "hold", "grid", "colorbar"];
                    if builtins_requiring_no_args.contains(&name.as_str()) {
                        return self.call_function(val, Vec::new(), 1);
                    }
                }
                Ok(val)
            }
            Stmt::Assignment { lhs, rhs } => {
                let val = match rhs {
                    Expr::FunctionCall { func, args } => {
                        self.eval_function_call_internal(func, args, lhs.len())?
                    }
                    _ => self.eval_expression(rhs)?,
                };

                if lhs.len() > 1 {
                    if let Value::List(vals) = val {
                        for (i, l) in lhs.iter().enumerate() {
                            if i < vals.len() {
                                self.assign_lhs(l, vals[i].clone())?;
                            } else {
                                self.assign_lhs(l, Value::Void)?;
                            }
                        }
                        return Ok(Value::List(vals));
                    }
                }

                for l in lhs {
                    self.assign_lhs(l, val.clone())?;
                }
                Ok(val)
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
                Ok(Value::Void)
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
                                Value::Matrix(col.to_owned().insert_axis(ndarray::Axis(1)))
                            };
                            self.env.write().unwrap().define(var.clone(), val);
                            last = self.eval_block(body)?;
                        }
                        Ok(last)
                    }
                    Value::ComplexMatrix(m) => {
                         let mut last = Value::Void;
                         for col in m.columns() {
                             let val = if col.len() == 1 {
                                 Value::Complex(col[0].re, col[0].im)
                             } else {
                                 Value::ComplexMatrix(col.to_owned().insert_axis(ndarray::Axis(1)))
                             };
                             self.env.write().unwrap().define(var.clone(), val);
                             last = self.eval_block(body)?;
                         }
                         Ok(last)
                    }
                    Value::CellArray(v) => {
                        let mut last = Value::Void;
                        for item in v {
                            self.env.write().unwrap().define(var.clone(), item);
                            last = self.eval_block(body)?;
                        }
                        Ok(last)
                    }
                    _ => Err(format!("Cannot iterate over {:?}", iter_val)),
                }
            }
            Stmt::While { condition, body } => {
                let mut last = Value::Void;
                while self.eval_expression(condition)?.is_truthy() {
                    last = self.eval_block(body)?;
                }
                Ok(last)
            }
            Stmt::FunctionDef { name, params, returns, body } => {
                let func = Value::Function {
                    name: name.clone(),
                    params: params.clone(),
                    returns: returns.clone(),
                    body: body.clone(),
                };
                self.env.write().unwrap().define(name.clone(), func);
                Ok(Value::Void)
            }
            Stmt::Clear(vars) => {
                if vars.is_empty() || vars.contains(&"all".to_string()) {
                    let mut keys_to_remove = Vec::new();
                    for (k, v) in self.env.read().unwrap().vars.iter() {
                        if !matches!(v, Value::Function { .. }) && !matches!(v, Value::FunctionHandle(_)) {
                            keys_to_remove.push(k.clone());
                        }
                    }
                    let mut env = self.env.write().unwrap();
                    for k in keys_to_remove {
                        env.vars.remove(&k);
                    }
                } else {
                    for v in vars {
                        self.env.write().unwrap().vars.remove(v);
                    }
                }
                Ok(Value::Void)
            }
            Stmt::CommandCall { command, args } => {
                let arg_vals = args.iter().map(|a| Value::String(a.clone())).collect();
                self.call_function(Value::FunctionHandle(command.clone()), arg_vals, 0)
            }
            Stmt::Return => Ok(Value::Void),
            _ => Err(format!("Statement not yet implemented: {:?}", stmt)),
        }
    }

    fn assign_lhs(&mut self, l: &Expr, val: Value) -> Result<(), String> {
        match l {
            Expr::Identifier(name) => {
                eprintln!("Defining identifier: {} = {:?}", name, val);
                self.env.write().unwrap().define(name.clone(), val);
            }
            Expr::FunctionCall { func, args } => {
                 if let Expr::Identifier(name) = &**func {
                     let target_val_opt = self.env.read().unwrap().get(name);
                     if let Some(mut target_val) = target_val_opt {
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
                             if !end_vals.is_empty() {
                                 let ev = if end_vals.len() == 1 { end_vals[0] }
                                          else if i < end_vals.len() { end_vals[i] }
                                          else { *end_vals.last().unwrap() };
                                 self.end_stack.push(ev);
                                 let res = self.eval_expression(a);
                                 self.end_stack.pop();
                                 idx_vals.push(res?);
                             } else {
                                 idx_vals.push(self.eval_expression(a)?);
                             }
                         }

                         match &mut target_val {
                             Value::Matrix(m) => {
                                 if idx_vals.len() == 1 {
                                     let is_logical = if let Value::Matrix(mat) = &idx_vals[0] {
                                         mat.iter().any(|&x| x == 0.0)
                                     } else { false };

                                     if is_logical {
                                         if let Value::Matrix(mat) = &idx_vals[0] {
                                             let mut src_idx = 0;
                                             let src_flat: Vec<f64> = match &val {
                                                 Value::Matrix(m) => m.iter().cloned().collect(),
                                                 Value::Scalar(n) => vec![*n],
                                                 _ => Vec::new(),
                                             };
                                             let slice = m.as_slice_mut().unwrap();
                                             for (i, &mask_val) in mat.iter().enumerate() {
                                                 if mask_val != 0.0 {
                                                     let fill_val = if src_flat.len() == 1 { src_flat[0] }
                                                                    else { *src_flat.get(src_idx).unwrap_or(&0.0) };
                                                     slice[i] = fill_val;
                                                     src_idx += 1;
                                                 }
                                             }
                                         }
                                     } else {
                                         let indices: Vec<usize> = match &idx_vals[0] {
                                             Value::Scalar(i) => vec![*i as usize - 1],
                                             Value::Matrix(mat) => mat.iter().map(|&i| i as usize - 1).collect(),
                                             Value::Colon => (0..m.len()).collect(),
                                             _ => return Err("Invalid index type".to_string()),
                                         };
                                         if let Value::Scalar(v) = val {
                                             let slice = m.as_slice_mut().unwrap();
                                             for idx in indices { slice[idx] = v; }
                                         } else if let Value::Matrix(src) = val {
                                             let slice = m.as_slice_mut().unwrap();
                                             for (i, idx) in indices.into_iter().enumerate() {
                                                 slice[idx] = src.as_slice().unwrap()[i];
                                             }
                                         }
                                     }
                                 } else if idx_vals.len() == 2 {
                                     let rows: Vec<usize> = match &idx_vals[0] {
                                         Value::Scalar(r) => vec![*r as usize - 1],
                                         Value::Matrix(mat) => mat.iter().map(|&r| r as usize - 1).collect(),
                                         Value::Colon => (0..m.nrows()).collect(),
                                         _ => return Err("Invalid row index".to_string()),
                                     };
                                     let cols: Vec<usize> = match &idx_vals[1] {
                                         Value::Scalar(c) => vec![*c as usize - 1],
                                         Value::Matrix(mat) => mat.iter().map(|&c| c as usize - 1).collect(),
                                         Value::Colon => (0..m.ncols()).collect(),
                                         _ => return Err("Invalid col index".to_string()),
                                     };
                                     if let Value::Scalar(v) = val {
                                         for r in &rows { for c in &cols { m[[*r, *c]] = v; } }
                                     } else if let Value::Matrix(src) = val {
                                         for (ri, r) in rows.iter().enumerate() {
                                             for (ci, c) in cols.iter().enumerate() {
                                                 m[[*r, *c]] = src[[ri, ci]];
                                             }
                                         }
                                     }
                                 }
                                 self.env.write().unwrap().define(name.clone(), Value::Matrix(m.clone()));
                             }
                             Value::CellArray(v) => {
                                 if idx_vals.len() == 1 {
                                     if let Value::Scalar(i) = &idx_vals[0] {
                                         let idx = *i as usize - 1;
                                         if idx < v.len() { v[idx] = val; }
                                     }
                                     self.env.write().unwrap().define(name.clone(), Value::CellArray(v.clone()));
                                 }
                             }
                             _ => {}
                         }
                     }
                 }
            }
            Expr::PropertyAccess { target, property } => {
                let target_val = self.eval_expression(target).unwrap_or(Value::Struct(std::collections::HashMap::new()));
                if let Value::Struct(mut map) = target_val {
                    map.insert(property.clone(), val);
                    if let Expr::Identifier(name) = &**target {
                        self.env.write().unwrap().define(name.clone(), Value::Struct(map));
                    }
                }
            }
            Expr::CellIndexing { target, args } => {
                 if let Expr::Identifier(name) = &**target {
                     let idx_vals = args.iter().map(|a| self.eval_expression(a)).collect::<Result<Vec<Value>, String>>()?;
                     let mut env = self.env.write().unwrap();
                     if let Some(Value::CellArray(mut v)) = env.get(name) {
                         if idx_vals.len() == 1 {
                             if let Value::Scalar(i) = &idx_vals[0] {
                                 let idx = *i as usize - 1;
                                 if idx < v.len() {
                                     v[idx] = val;
                                     env.define(name.clone(), Value::CellArray(v));
                                 }
                             }
                         }
                     }
                 }
            }
            _ => return Err(format!("Complex assignment not yet implemented: {:?}", l)),
        }
        Ok(())
    }

    fn eval_block(&mut self, statements: &Vec<Stmt>) -> Result<Value, String> {
        let mut last = Value::Void;
        for s in statements {
            last = self.eval_statement(s)?;
            if let Stmt::Return = s { break; }
        }
        Ok(last)
    }

    fn eval_function_call_internal(&mut self, func: &Expr, args: &Vec<Expr>, nargout: usize) -> Result<Value, String> {
        // eprintln!("Evaluating FunctionCall with target: {:?} and {} args", func, args.len());
        let f_val = self.eval_expression(func)?;
        if let Value::CellArray(_) = f_val {
            // eprintln!("Calling CellArray as function: {:?} with {} args", func, args.len());
        }
        
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
                        for item in v { arg_vals.push(item); }
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
            Expr::String(s) => Ok(Value::String(s.clone())),
            Expr::End => {
                if let Some(val) = self.end_stack.last() {
                    Ok(Value::Scalar(*val))
                } else {
                    Err("end used outside of indexing context".to_string())
                }
            }
            Expr::Colon => Ok(Value::Colon),
            Expr::Identifier(name) => {
                if let Some(val) = self.env.read().unwrap().get(name) {
                    return Ok(val);
                }
                
                let builtins_requiring_no_args = vec!["clc", "tic", "toc", "clf", "cla", "gcf", "gca", "hold", "grid", "colorbar", "figure", "close", "pause"];
                if builtins_requiring_no_args.contains(&name.as_str()) {
                    return self.call_function(Value::FunctionHandle(name.clone()), Vec::new(), 1);
                }

                if self.find_m_file(name).is_some() {
                    return Ok(Value::FunctionHandle(name.clone()));
                }
                Err(format!("Undefined variable or function: {}", name))
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
                    (UnaryOperator::Minus, Value::Matrix(m)) => Ok(Value::Matrix(m.mapv(|x| -x))),
                    (UnaryOperator::Minus, Value::ComplexMatrix(m)) => Ok(Value::ComplexMatrix(m.mapv(|x| -x))),
                    (UnaryOperator::Not, v) => Ok(Value::Bool(!v.is_truthy())),
                    _ => Err("Invalid unary operation".to_string()),
                }
            }
            Expr::FunctionCall { func, args } => {
                self.eval_function_call_internal(func, args, 1)
            }
            Expr::CellIndexing { target, args } => {
                let t_val = self.eval_expression(target)?;
                let mut arg_vals = Vec::new();
                
                let end_vals = match &t_val {
                    Value::CellArray(v) => vec![v.len() as f64],
                    Value::Matrix(m) => {
                        if args.len() == 1 { vec![m.len() as f64] }
                        else { vec![m.nrows() as f64, m.ncols() as f64] }
                    }
                    _ => Vec::new(),
                };

                for (i, a) in args.iter().enumerate() {
                    if !end_vals.is_empty() {
                        let ev = if end_vals.len() == 1 { end_vals[0] }
                                 else if i < end_vals.len() { end_vals[i] }
                                 else { *end_vals.last().unwrap() };
                        self.end_stack.push(ev);
                        let res = self.eval_expression(a);
                        self.end_stack.pop();
                        arg_vals.push(res?);
                    } else {
                        arg_vals.push(self.eval_expression(a)?);
                    }
                }

                match t_val {
                    Value::CellArray(v) => {
                        if arg_vals.len() == 1 {
                            match &arg_vals[0] {
                                Value::Scalar(i) => {
                                    let idx = *i as usize - 1;
                                    if idx < v.len() {
                                        return Ok(v[idx].clone());
                                    }
                                }
                                Value::Matrix(indices) => {
                                    let mut res = Vec::new();
                                    for &idx_val in indices {
                                        res.push(v[idx_val as usize - 1].clone());
                                    }
                                    return Ok(Value::CellArray(res));
                                }
                                Value::Colon => return Ok(Value::CellArray(v.clone())),
                                _ => {}
                            }
                        }
                        Err("Invalid cell indexing".to_string())
                    }
                    _ => Err("Cell indexing only supported on cell arrays".to_string()),
                }
            }
            Expr::Matrix(rows) => {
                if rows.is_empty() {
                    return Ok(Value::Matrix(Array2::zeros((0, 0))));
                }
                
                let mut block_rows = Vec::new();
                let mut is_complex = false;
                
                for row in rows {
                    let mut block_row = Vec::new();
                    for entry in row {
                        let val = self.eval_expression(entry)?;
                        match &val {
                            Value::ComplexMatrix(_) | Value::Complex(_, _) => is_complex = true,
                            _ => {}
                        }
                        block_row.push(val);
                    }
                    block_rows.push(block_row);
                }

                // Convert all to ComplexMatrix if any is complex, otherwise Matrix
                if is_complex {
                    let mut final_rows = Vec::new();
                    for row in block_rows {
                        let mut row_mats = Vec::new();
                        for val in &row {
                            match val {
                                Value::Scalar(n) => row_mats.push(Array2::from_elem((1, 1), Complex64::new(*n, 0.0))),
                                Value::Complex(re, im) => row_mats.push(Array2::from_elem((1, 1), Complex64::new(*re, *im))),
                                Value::Matrix(m) => row_mats.push(m.mapv(|x| Complex64::new(x, 0.0))),
                                Value::ComplexMatrix(m) => row_mats.push(m.clone()),
                                _ => return Ok(Value::CellArray(row.iter().cloned().collect())), // Fall back to CellArray if heterogeneous non-math
                            }
                        }
                        // Horizontal concat row
                        let views: Vec<_> = row_mats.iter().map(|m| m.view()).collect();
                        let row_concat = ndarray::concatenate(ndarray::Axis(1), &views).map_err(|e| e.to_string())?;
                        final_rows.push(row_concat);
                    }
                    // Vertical concat rows
                    let views: Vec<_> = final_rows.iter().map(|m| m.view()).collect();
                    let final_concat = ndarray::concatenate(ndarray::Axis(0), &views).map_err(|e| e.to_string())?;
                    Ok(Value::ComplexMatrix(final_concat))
                } else {
                    let mut final_rows = Vec::new();
                    for row in block_rows {
                        let mut row_mats = Vec::new();
                        for val in &row {
                            match val {
                                Value::Scalar(n) => row_mats.push(Array2::from_elem((1, 1), *n)),
                                Value::Matrix(m) => row_mats.push(m.clone()),
                                _ => return Ok(Value::CellArray(row.iter().cloned().collect())),
                            }
                        }
                        let views: Vec<_> = row_mats.iter().map(|m| m.view()).collect();
                        let row_concat = ndarray::concatenate(ndarray::Axis(1), &views).map_err(|e| e.to_string())?;
                        final_rows.push(row_concat);
                    }
                    let views: Vec<_> = final_rows.iter().map(|m| m.view()).collect();
                    let final_concat = ndarray::concatenate(ndarray::Axis(0), &views).map_err(|e| e.to_string())?;
                    Ok(Value::Matrix(final_concat))
                }
            }
            Expr::Transpose(inner) => {
                let v = self.eval_expression(inner)?;
                match v {
                    Value::Matrix(m) => Ok(Value::Matrix(m.reversed_axes())),
                    Value::ComplexMatrix(m) => Ok(Value::ComplexMatrix(m.reversed_axes())),
                    Value::Scalar(n) => Ok(Value::Scalar(n)),
                    Value::Complex(re, im) => Ok(Value::Complex(re, im)),
                    Value::String(s) => Ok(Value::String(s)),
                    Value::CellArray(c) => Ok(Value::CellArray(c)),
                    Value::Void => Ok(Value::Void),
                    _ => Err("Transpose not implemented for this type".to_string()),
                }
            }
            Expr::PropertyAccess { target, property } => {
                let val = self.eval_expression(target)?;
                match val {
                    Value::Struct(map) => {
                        map.get(property).cloned().ok_or_else(|| format!("Field not found: {}", property))
                    }
                    _ => Err("Property access only supported on structs".to_string()),
                }
            }
            Expr::CellArray(rows) => {
                let mut items = Vec::new();
                for row in rows {
                    for entry in row {
                        items.push(self.eval_expression(entry)?);
                    }
                }
                Ok(Value::CellArray(items))
            }
            Expr::FunctionHandle(name) => Ok(Value::FunctionHandle(name.clone())),
            Expr::KeywordArg(_, val) => self.eval_expression(val),
            Expr::AnonymousFunc { params, body } => {
                Ok(Value::AnonymousFunction {
                    params: params.clone(),
                    body: *body.clone(),
                })
            }
        }
    }

    fn eval_binary_op(&self, left: Value, op: &BinaryOperator, right: Value) -> Result<Value, String> {
        match (left.clone(), op, right.clone()) {
            (Value::String(a), op, Value::String(b)) => {
                match op {
                    BinaryOperator::Add => Ok(Value::String(format!("{}{}", a, b))),
                    BinaryOperator::Eq => Ok(Value::Bool(a == b)),
                    BinaryOperator::Ne => Ok(Value::Bool(a != b)),
                    _ => Err(format!("Operator {:?} not implemented for Strings", op)),
                }
            }
            (Value::Bool(a), op, Value::Bool(b)) => {
                match op {
                    BinaryOperator::Eq => Ok(Value::Bool(a == b)),
                    BinaryOperator::Ne => Ok(Value::Bool(a != b)),
                    BinaryOperator::And | BinaryOperator::ShortAnd => Ok(Value::Bool(a && b)),
                    BinaryOperator::Or | BinaryOperator::ShortOr => Ok(Value::Bool(a || b)),
                    _ => Err(format!("Operator {:?} not implemented for Bools", op)),
                }
            }
            (Value::Scalar(a), op, Value::Scalar(b)) => {
                match op {
                    BinaryOperator::Add => Ok(Value::Scalar(a + b)),
                    BinaryOperator::Sub => Ok(Value::Scalar(a - b)),
                    BinaryOperator::Mul | BinaryOperator::DotMul => Ok(Value::Scalar(a * b)),
                    BinaryOperator::Div | BinaryOperator::DotDiv => Ok(Value::Scalar(a / b)),
                    BinaryOperator::Pow | BinaryOperator::DotPow => Ok(Value::Scalar(a.powf(b))),
                    BinaryOperator::Eq => Ok(Value::Bool(a == b)),
                    BinaryOperator::Ne => Ok(Value::Bool(a != b)),
                    BinaryOperator::Gt => Ok(Value::Bool(a > b)),
                    BinaryOperator::Lt => Ok(Value::Bool(a < b)),
                    BinaryOperator::Ge => Ok(Value::Bool(a >= b)),
                    BinaryOperator::Le => Ok(Value::Bool(a <= b)),
                    BinaryOperator::And | BinaryOperator::ShortAnd => Ok(Value::Bool((a != 0.0) && (b != 0.0))),
                    BinaryOperator::Or | BinaryOperator::ShortOr => Ok(Value::Bool((a != 0.0) || (b != 0.0))),
                    _ => Err(format!("Operator {:?} not implemented for Scalars", op)),
                }
            }
            (Value::Complex(re1, im1), op, Value::Scalar(b)) => {
                let a = Complex64::new(re1, im1);
                match op {
                    BinaryOperator::Add => { let r = a + b; Ok(Value::Complex(r.re, r.im)) }
                    BinaryOperator::Sub => { let r = a - b; Ok(Value::Complex(r.re, r.im)) }
                    BinaryOperator::Mul | BinaryOperator::DotMul => { let r = a * b; Ok(Value::Complex(r.re, r.im)) }
                    BinaryOperator::Div | BinaryOperator::DotDiv => { let r = a / b; Ok(Value::Complex(r.re, r.im)) }
                    BinaryOperator::Pow | BinaryOperator::DotPow => { let r = a.powf(b); Ok(Value::Complex(r.re, r.im)) }
                    _ => Err(format!("Operator {:?} not implemented for Complex/Scalar", op)),
                }
            }
            (Value::Scalar(a), op, Value::Complex(re2, im2)) => {
                let b = Complex64::new(re2, im2);
                match op {
                    BinaryOperator::Add => { let r = a + b; Ok(Value::Complex(r.re, r.im)) }
                    BinaryOperator::Sub => { let r = a - b; Ok(Value::Complex(r.re, r.im)) }
                    BinaryOperator::Mul | BinaryOperator::DotMul => { let r = a * b; Ok(Value::Complex(r.re, r.im)) }
                    BinaryOperator::Div | BinaryOperator::DotDiv => { let r = a / b; Ok(Value::Complex(r.re, r.im)) }
                    _ => Err(format!("Operator {:?} not implemented for Scalar/Complex", op)),
                }
            }
            (Value::Complex(re1, im1), op, Value::Complex(re2, im2)) => {
                let a = Complex64::new(re1, im1);
                let b = Complex64::new(re2, im2);
                match op {
                    BinaryOperator::Add => { let r = a + b; Ok(Value::Complex(r.re, r.im)) }
                    BinaryOperator::Sub => { let r = a - b; Ok(Value::Complex(r.re, r.im)) }
                    BinaryOperator::Mul | BinaryOperator::DotMul => { let r = a * b; Ok(Value::Complex(r.re, r.im)) }
                    BinaryOperator::Div | BinaryOperator::DotDiv => { let r = a / b; Ok(Value::Complex(r.re, r.im)) }
                    _ => Err(format!("Operator {:?} not implemented for Complex/Complex", op)),
                }
            }
            (Value::Matrix(a), op, Value::Matrix(b)) => {
                match op {
                    BinaryOperator::Add => Ok(Value::Matrix(a + b)),
                    BinaryOperator::Sub => Ok(Value::Matrix(a - b)),
                    BinaryOperator::Mul => Ok(Value::Matrix(a.dot(&b))),
                    BinaryOperator::Div => Ok(Value::Matrix(a / b)),
                    BinaryOperator::DotMul => Ok(Value::Matrix(a * b)),
                    BinaryOperator::DotDiv => Ok(Value::Matrix(a / b)),
                    BinaryOperator::LDiv | BinaryOperator::DotLDiv => {
                        // Fall back to Python for LDiv
                        PythonBridge::call_runtime_func("mldivide", vec![Value::Matrix(a), Value::Matrix(b)], 1).map_err(|e| e.to_string())
                    }
                    BinaryOperator::DotPow => {
                        let mut res = a.clone();
                        for (i, val) in res.iter_mut().enumerate() {
                            *val = val.powf(b.as_slice().unwrap()[i]);
                        }
                        Ok(Value::Matrix(res))
                    }
                    BinaryOperator::Eq => {
                        let res = Array2::from_shape_fn(a.raw_dim(), |d| a[d] == b[d]);
                        Ok(Value::LogicalMatrix(res))
                    }
                    BinaryOperator::Ne => {
                        let res = Array2::from_shape_fn(a.raw_dim(), |d| a[d] != b[d]);
                        Ok(Value::LogicalMatrix(res))
                    }
                    _ => Err(format!("Operator {:?} not implemented for Matrix/Matrix", op)),
                }
            }
            (Value::Bool(a), op, Value::Scalar(b)) => {
                let a_val = if a { 1.0 } else { 0.0 };
                match op {
                    BinaryOperator::Add => Ok(Value::Scalar(a_val + b)),
                    BinaryOperator::Sub => Ok(Value::Scalar(a_val - b)),
                    BinaryOperator::Mul | BinaryOperator::DotMul => Ok(Value::Scalar(a_val * b)),
                    BinaryOperator::Div | BinaryOperator::DotDiv => Ok(Value::Scalar(a_val / b)),
                    _ => Err(format!("Operator {:?} not implemented for Bool/Scalar", op)),
                }
            }
            (Value::Scalar(a), op, Value::Bool(b)) => {
                let b_val = if b { 1.0 } else { 0.0 };
                match op {
                    BinaryOperator::Add => Ok(Value::Scalar(a + b_val)),
                    BinaryOperator::Sub => Ok(Value::Scalar(a - b_val)),
                    BinaryOperator::Mul | BinaryOperator::DotMul => Ok(Value::Scalar(a * b_val)),
                    BinaryOperator::Div | BinaryOperator::DotDiv => Ok(Value::Scalar(a / b_val)),
                    _ => Err(format!("Operator {:?} not implemented for Scalar/Bool", op)),
                }
            }
            (Value::Matrix(a), op, Value::Bool(b)) => {
                let b_val = if b { 1.0 } else { 0.0 };
                match op {
                    BinaryOperator::Add => Ok(Value::Matrix(a.mapv(|x| x + b_val))),
                    BinaryOperator::Sub => Ok(Value::Matrix(a.mapv(|x| x - b_val))),
                    BinaryOperator::Mul | BinaryOperator::DotMul => Ok(Value::Matrix(a.mapv(|x| x * b_val))),
                    BinaryOperator::Div | BinaryOperator::DotDiv => Ok(Value::Matrix(a.mapv(|x| x / b_val))),
                    _ => Err(format!("Operator {:?} not implemented for Matrix/Bool", op)),
                }
            }
            (Value::Bool(a), op, Value::Matrix(b)) => {
                let a_val = if a { 1.0 } else { 0.0 };
                match op {
                    BinaryOperator::Add => Ok(Value::Matrix(b.mapv(|x| a_val + x))),
                    BinaryOperator::Sub => Ok(Value::Matrix(b.mapv(|x| a_val - x))),
                    BinaryOperator::Mul | BinaryOperator::DotMul => Ok(Value::Matrix(b.mapv(|x| a_val * x))),
                    BinaryOperator::Div | BinaryOperator::DotDiv => Ok(Value::Matrix(b.mapv(|x| a_val / x))),
                    _ => Err(format!("Operator {:?} not implemented for Bool/Matrix", op)),
                }
            }
            (Value::Matrix(a), op, Value::Scalar(b)) => {
                match op {
                    BinaryOperator::Add => Ok(Value::Matrix(a.mapv(|x| x + b))),
                    BinaryOperator::Sub => Ok(Value::Matrix(a.mapv(|x| x - b))),
                    BinaryOperator::Mul | BinaryOperator::DotMul => Ok(Value::Matrix(a.mapv(|x| x * b))),
                    BinaryOperator::Div | BinaryOperator::DotDiv => Ok(Value::Matrix(a.mapv(|x| x / b))),
                    BinaryOperator::Pow | BinaryOperator::DotPow => Ok(Value::Matrix(a.mapv(|x| x.powf(b)))),
                    BinaryOperator::Eq => Ok(Value::LogicalMatrix(a.mapv(|x| x == b))),
                    BinaryOperator::Ne => Ok(Value::LogicalMatrix(a.mapv(|x| x != b))),
                    BinaryOperator::Lt => Ok(Value::LogicalMatrix(a.mapv(|x| x < b))),
                    BinaryOperator::Gt => Ok(Value::LogicalMatrix(a.mapv(|x| x > b))),
                    BinaryOperator::Le => Ok(Value::LogicalMatrix(a.mapv(|x| x <= b))),
                    BinaryOperator::Ge => Ok(Value::LogicalMatrix(a.mapv(|x| x >= b))),
                    _ => Err(format!("Operator {:?} not implemented for Matrix/Scalar", op)),
                }
            }
            (Value::Scalar(a), op, Value::Matrix(b)) => {
                match op {
                    BinaryOperator::Add => Ok(Value::Matrix(b.mapv(|x| a + x))),
                    BinaryOperator::Sub => Ok(Value::Matrix(b.mapv(|x| a - x))),
                    BinaryOperator::Mul | BinaryOperator::DotMul => Ok(Value::Matrix(b.mapv(|x| a * x))),
                    BinaryOperator::Div | BinaryOperator::DotDiv => Ok(Value::Matrix(b.mapv(|x| a / x))),
                    BinaryOperator::Eq => Ok(Value::LogicalMatrix(b.mapv(|x| a == x))),
                    BinaryOperator::Ne => Ok(Value::LogicalMatrix(b.mapv(|x| a != x))),
                    BinaryOperator::Lt => Ok(Value::LogicalMatrix(b.mapv(|x| a < x))),
                    BinaryOperator::Gt => Ok(Value::LogicalMatrix(b.mapv(|x| a > x))),
                    BinaryOperator::Le => Ok(Value::LogicalMatrix(b.mapv(|x| a <= x))),
                    BinaryOperator::Ge => Ok(Value::LogicalMatrix(b.mapv(|x| a >= x))),
                    _ => Err(format!("Operator {:?} not implemented for Scalar/Matrix", op)),
                }
            }
            (Value::ComplexMatrix(a), op, Value::ComplexMatrix(b)) => {
                 match op {
                     BinaryOperator::Add => Ok(Value::ComplexMatrix(a + b)),
                     BinaryOperator::Sub => Ok(Value::ComplexMatrix(a - b)),
                     BinaryOperator::DotMul => Ok(Value::ComplexMatrix(a * b)),
                     BinaryOperator::DotDiv => Ok(Value::ComplexMatrix(a / b)),
                     _ => Err(format!("Operator {:?} not implemented for ComplexMatrix/ComplexMatrix", op)),
                 }
            }
            (Value::Matrix(a), op, Value::ComplexMatrix(b)) => {
                 match op {
                     BinaryOperator::Add | BinaryOperator::DotAdd => {
                         let res = a.mapv(|x| Complex64::new(x, 0.0)) + b;
                         Ok(Value::ComplexMatrix(res))
                     }
                     BinaryOperator::Sub | BinaryOperator::DotSub => {
                         let res = a.mapv(|x| Complex64::new(x, 0.0)) - b;
                         Ok(Value::ComplexMatrix(res))
                     }
                     BinaryOperator::Mul => {
                         let res = a.mapv(|x| Complex64::new(x, 0.0)).dot(&b);
                         Ok(Value::ComplexMatrix(res))
                     }
                     BinaryOperator::DotMul => {
                         let res = a.mapv(|x| Complex64::new(x, 0.0)) * b;
                         Ok(Value::ComplexMatrix(res))
                     }
                     BinaryOperator::DotDiv => {
                         let res = a.mapv(|x| Complex64::new(x, 0.0)) / b;
                         Ok(Value::ComplexMatrix(res))
                     }
                     _ => Err(format!("Operator {:?} not implemented for Matrix/ComplexMatrix", op)),
                 }
            }
            (Value::ComplexMatrix(a), op, Value::Matrix(b)) => {
                 match op {
                     BinaryOperator::Add | BinaryOperator::DotAdd => {
                         let res = a + b.mapv(|x| Complex64::new(x, 0.0));
                         Ok(Value::ComplexMatrix(res))
                     }
                     BinaryOperator::Sub | BinaryOperator::DotSub => {
                         let res = a - b.mapv(|x| Complex64::new(x, 0.0));
                         Ok(Value::ComplexMatrix(res))
                     }
                     BinaryOperator::Mul => {
                         let res = a.dot(&b.mapv(|x| Complex64::new(x, 0.0)));
                         Ok(Value::ComplexMatrix(res))
                     }
                     BinaryOperator::DotMul => {
                         let res = a * b.mapv(|x| Complex64::new(x, 0.0));
                         Ok(Value::ComplexMatrix(res))
                     }
                     BinaryOperator::DotDiv => {
                         let res = a / b.mapv(|x| Complex64::new(x, 0.0));
                         Ok(Value::ComplexMatrix(res))
                     }
                     _ => Err(format!("Operator {:?} not implemented for ComplexMatrix/Matrix", op)),
                 }
            }
            (Value::ComplexMatrix(a), op, Value::Scalar(b)) => {
                match op {
                    BinaryOperator::Add => Ok(Value::ComplexMatrix(a.mapv(|x| x + b))),
                    BinaryOperator::Sub => Ok(Value::ComplexMatrix(a.mapv(|x| x - b))),
                    BinaryOperator::Mul | BinaryOperator::DotMul => Ok(Value::ComplexMatrix(a.mapv(|x| x * b))),
                    BinaryOperator::Div | BinaryOperator::DotDiv => Ok(Value::ComplexMatrix(a.mapv(|x| x / b))),
                    _ => Err(format!("Operator {:?} not implemented for ComplexMatrix/Scalar", op)),
                }
            }
            (Value::Scalar(a), op, Value::ComplexMatrix(b)) => {
                match op {
                    BinaryOperator::Add => Ok(Value::ComplexMatrix(b.mapv(|x| a + x))),
                    BinaryOperator::Sub => Ok(Value::ComplexMatrix(b.mapv(|x| a - x))),
                    BinaryOperator::Mul | BinaryOperator::DotMul => Ok(Value::ComplexMatrix(b.mapv(|x| a * x))),
                    BinaryOperator::Div | BinaryOperator::DotDiv => Ok(Value::ComplexMatrix(b.mapv(|x| a / x))),
                    _ => Err(format!("Operator {:?} not implemented for Scalar/ComplexMatrix", op)),
                }
            }
            (Value::ComplexMatrix(a), op, Value::Complex(re, im)) => {
                let b = Complex64::new(re, im);
                match op {
                    BinaryOperator::Add => Ok(Value::ComplexMatrix(a.mapv(|x| x + b))),
                    BinaryOperator::Sub => Ok(Value::ComplexMatrix(a.mapv(|x| x - b))),
                    BinaryOperator::Mul | BinaryOperator::DotMul => Ok(Value::ComplexMatrix(a.mapv(|x| x * b))),
                    BinaryOperator::Div | BinaryOperator::DotDiv => Ok(Value::ComplexMatrix(a.mapv(|x| x / b))),
                    _ => Err(format!("Operator {:?} not implemented for ComplexMatrix/Complex", op)),
                }
            }
            (Value::Complex(re, im), op, Value::ComplexMatrix(b)) => {
                let a = Complex64::new(re, im);
                match op {
                    BinaryOperator::Add => Ok(Value::ComplexMatrix(b.mapv(|x| a + x))),
                    BinaryOperator::Sub => Ok(Value::ComplexMatrix(b.mapv(|x| a - x))),
                    BinaryOperator::Mul | BinaryOperator::DotMul => Ok(Value::ComplexMatrix(b.mapv(|x| a * x))),
                    BinaryOperator::Div | BinaryOperator::DotDiv => Ok(Value::ComplexMatrix(b.mapv(|x| a / x))),
                    _ => Err(format!("Operator {:?} not implemented for Complex/ComplexMatrix", op)),
                }
            }
            (Value::Complex(re, im), op, Value::Matrix(b)) => {
                let a = Complex64::new(re, im);
                match op {
                    BinaryOperator::Mul | BinaryOperator::DotMul => Ok(Value::ComplexMatrix(b.mapv(|x| a * x))),
                    _ => Err(format!("Operator {:?} not implemented for Complex/Matrix", op)),
                }
            }
            (Value::Matrix(a), op, Value::Complex(re, im)) => {
                let b = Complex64::new(re, im);
                match op {
                    BinaryOperator::Mul | BinaryOperator::DotMul => Ok(Value::ComplexMatrix(a.mapv(|x| x * b))),
                    _ => Err(format!("Operator {:?} not implemented for Matrix/Complex", op)),
                }
            }
            _ => Err(format!("Binary operation {:?} not yet implemented for these types: {:?} and {:?}", op, left, right)),
        }
    }

    fn call_function(&mut self, func: Value, args: Vec<Value>, nargout: usize) -> Result<Value, String> {
        match func {
            Value::Function { name: _, params, returns, body } => {
                let parent_env = self.env.clone();
                let new_env = Arc::new(RwLock::new(Environment::with_parent(parent_env)));
                for (i, p_name) in params.iter().enumerate() {
                    if i < args.len() {
                        new_env.write().unwrap().define(p_name.clone(), args[i].clone());
                    }
                }
                new_env.write().unwrap().define("nargin".to_string(), Value::Scalar(args.len() as f64));
                new_env.write().unwrap().define("nargout".to_string(), Value::Scalar(nargout.max(1) as f64));
                let old_env = std::mem::replace(&mut self.env, new_env);
                let _ = self.eval_block(&body)?;
                
                let mut res_vals = Vec::new();
                if returns.len() == 1 && returns[0] == "varargout" {
                    if let Some(Value::CellArray(v)) = self.env.read().unwrap().get("varargout") {
                        res_vals = v;
                    }
                } else {
                    for ret_name in &returns {
                        res_vals.push(self.env.read().unwrap().get(ret_name).unwrap_or(Value::Void));
                    }
                }

                self.env = old_env;
                if res_vals.is_empty() {
                    Ok(Value::Void)
                } else if res_vals.len() == 1 {
                    Ok(res_vals[0].clone())
                } else {
                    Ok(Value::List(res_vals))
                }
            }
            Value::AnonymousFunction { params, body } => {
                let parent_env = self.env.clone();
                let new_env = Arc::new(RwLock::new(Environment::with_parent(parent_env)));
                for (i, p_name) in params.iter().enumerate() {
                    if i < args.len() {
                        new_env.write().unwrap().define(p_name.clone(), args[i].clone());
                    }
                }
                new_env.write().unwrap().define("nargin".to_string(), Value::Scalar(args.len() as f64));
                new_env.write().unwrap().define("nargout".to_string(), Value::Scalar(1.0));
                let old_env = std::mem::replace(&mut self.env, new_env);
                let res = self.eval_expression(&body)?;
                self.env = old_env;
                Ok(res)
            }
            Value::FunctionHandle(name) => {
                match name.as_str() {
                    "disp" => {
                        for a in args {
                            println!("{}", a);
                        }
                        Ok(Value::Void)
                    }
                    "num2str" => {
                        if args.len() == 1 {
                            return Ok(Value::String(format!("{}", args[0])));
                        }
                        Err("Invalid num2str args".to_string())
                    }
                    "fprintf" => {
                        if args.len() >= 1 {
                            if let Value::String(fmt) = &args[0] {
                                let mut res = fmt.clone();
                                for i in 1..args.len() {
                                    res = res.replacen("%s", &format!("{}", args[i]), 1);
                                    res = res.replacen("%d", &format!("{}", args[i]), 1);
                                    res = res.replacen("%.2f", &format!("{}", args[i]), 1);
                                    res = res.replacen("%.3f", &format!("{}", args[i]), 1);
                                    res = res.replacen("%.4f", &format!("{}", args[i]), 1);
                                    res = res.replacen("%f", &format!("{}", args[i]), 1);
                                }
                                print!("{}", res);
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
                                return Ok(Value::Matrix(Array2::from_shape_vec((1, len), v).unwrap()));
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
                                if len == 0 {
                                    return Ok(Value::Matrix(Array2::zeros((0, 0))));
                                }
                                return Ok(Value::Matrix(Array2::from_shape_vec((1, len), v).unwrap()));
                            }
                        }
                        Err("Invalid range args".to_string())
                    }
                    "length" => {
                        if let Some(v) = args.first() {
                            match v {
                                Value::Matrix(m) => return Ok(Value::Scalar(m.nrows().max(m.ncols()) as f64)),
                                Value::ComplexMatrix(m) => return Ok(Value::Scalar(m.nrows().max(m.ncols()) as f64)),
                                Value::CellArray(c) => return Ok(Value::Scalar(c.len() as f64)),
                                Value::String(s) => return Ok(Value::Scalar(s.len() as f64)),
                                _ => return Ok(Value::Scalar(1.0)),
                            }
                        }
                        Err("Invalid length args".to_string())
                    }
                    "find" => {
                         if let Some(Value::Matrix(m)) = args.first() {
                             let mut indices = Vec::new();
                             for (i, &val) in m.iter().enumerate() {
                                 if val != 0.0 {
                                     indices.push((i + 1) as f64);
                                 }
                             }
                             return Ok(Value::Matrix(Array2::from_shape_vec((1, indices.len()), indices).unwrap()));
                         }
                         Err("Invalid find args".to_string())
                    }
                    "struct" => {
                        let mut map = std::collections::HashMap::new();
                        for i in (0..args.len()).step_by(2) {
                            if let Value::String(key) = &args[i] {
                                if i + 1 < args.len() {
                                    map.insert(key.clone(), args[i+1].clone());
                                }
                            }
                        }
                        Ok(Value::Struct(map))
                    }
                    "size" => {
                        if args.len() == 1 {
                            let (rows, cols) = match &args[0] {
                                Value::Matrix(m) => (m.nrows(), m.ncols()),
                                Value::ComplexMatrix(m) => (m.nrows(), m.ncols()),
                                _ => (1, 1),
                            };
                            if nargout > 1 {
                                return Ok(Value::List(vec![Value::Scalar(rows as f64), Value::Scalar(cols as f64)]));
                            }
                            let res = vec![rows as f64, cols as f64];
                            return Ok(Value::Matrix(Array2::from_shape_vec((1, 2), res).unwrap()));
                        } else if args.len() == 2 {
                            let dim = match &args[1] {
                                Value::Scalar(n) => *n as usize,
                                _ => return Err("Dimension must be a scalar".to_string()),
                            };
                            match &args[0] {
                                Value::Matrix(m) => {
                                    if dim == 1 { return Ok(Value::Scalar(m.nrows() as f64)); }
                                    else if dim == 2 { return Ok(Value::Scalar(m.ncols() as f64)); }
                                    else { return Ok(Value::Scalar(1.0)); }
                                }
                                Value::ComplexMatrix(m) => {
                                    if dim == 1 { return Ok(Value::Scalar(m.nrows() as f64)); }
                                    else if dim == 2 { return Ok(Value::Scalar(m.ncols() as f64)); }
                                    else { return Ok(Value::Scalar(1.0)); }
                                }
                                _ => return Ok(Value::Scalar(1.0)),
                            }
                        }
                        Err("Invalid size args".to_string())
                    }
                    "plot" => {
                        if args.len() >= 2 {
                             PythonBridge::call_plot(&args[0], &args[1]).map_err(|e| e.to_string())?;
                             if let (Value::Matrix(x), Value::Matrix(y)) = (&args[0], &args[1]) {
                                 self.plots.push(PlotData {
                                     plot_type: "line".to_string(),
                                     x: x.iter().cloned().collect(),
                                     y: y.iter().cloned().collect(),
                                     title: None, xlabel: None, ylabel: None,
                                 });
                             }
                             return Ok(Value::Void);
                        }
                        Err("Invalid plot args".to_string())
                    }
                    "simulate" => {
                          if args.len() >= 1 {
                              PythonBridge::call_simulate(&args[0], args[1..].to_vec()).map_err(|e| e.to_string())?;
                              return Ok(Value::Void);
                          }
                          Err("Invalid simulate args".to_string())
                    }
                    "sum" | "mean" | "std" | "var" | "min" | "max" | "round" | "floor" | "ceil" |
                    "sin" | "cos" | "tan" | "tanh" | "sinh" | "cosh" | "asinh" | "acosh" | "atanh" | "exp" | "log" | "log10" | "sqrt" | "abs" |
                    "rand" | "randn" | "randperm" | "reshape" | "linspace" | "zeros" | "ones" | "eye" |
                    "factorial" | "trapz" | "inv" | "eig" | "diag" | "norm" | "det" | "mod" | "rem" | "meshgrid" |
                    "real" | "imag" | "sort" | "sign" | "fft" | "ifft" |
                    "ischar" | "iscell" | "isnumeric" | "strcmp" | "isequal" |
                    "argmin" | "argmax" | "isempty" => {
                        if args.len() == 1 {
                            match name.as_str() {
                                "ischar" => return Ok(Value::Bool(matches!(args[0], Value::String(_)))),
                                "iscell" => return Ok(Value::Bool(matches!(args[0], Value::CellArray(_)))),
                                "isnumeric" => return Ok(Value::Bool(matches!(args[0], Value::Scalar(_) | Value::Matrix(_) | Value::Complex(_, _) | Value::ComplexMatrix(_)))),
                                "isempty" => {
                                    match &args[0] {
                                        Value::Matrix(m) => return Ok(Value::Bool(m.is_empty())),
                                        Value::ComplexMatrix(m) => return Ok(Value::Bool(m.is_empty())),
                                        Value::CellArray(v) => return Ok(Value::Bool(v.is_empty())),
                                        Value::String(s) => return Ok(Value::Bool(s.is_empty())),
                                        Value::Void => return Ok(Value::Bool(true)),
                                        _ => return Ok(Value::Bool(false)),
                                    }
                                }
                                "sign" => { if let Value::Scalar(n) = args[0] { return Ok(Value::Scalar(n.signum())); } }
                                "real" => {
                                    match &args[0] {
                                        Value::Scalar(n) => return Ok(Value::Scalar(*n)),
                                        Value::Complex(re, _) => return Ok(Value::Scalar(*re)),
                                        Value::Matrix(m) => return Ok(Value::Matrix(m.clone())),
                                        Value::ComplexMatrix(m) => return Ok(Value::Matrix(m.mapv(|x| x.re))),
                                        _ => {}
                                    }
                                }
                                "imag" => {
                                    match &args[0] {
                                        Value::Scalar(_) => return Ok(Value::Scalar(0.0)),
                                        Value::Complex(_, im) => return Ok(Value::Scalar(*im)),
                                        Value::Matrix(m) => return Ok(Value::Matrix(Array2::zeros(m.raw_dim()))),
                                        Value::ComplexMatrix(m) => return Ok(Value::Matrix(m.mapv(|x| x.im))),
                                        _ => {}
                                    }
                                }
                                "exp" => { if let Value::Scalar(n) = args[0] { return Ok(Value::Scalar(n.exp())); } }
                                "sin" => { if let Value::Scalar(n) = args[0] { return Ok(Value::Scalar(n.sin())); } }
                                "cos" => { if let Value::Scalar(n) = args[0] { return Ok(Value::Scalar(n.cos())); } }
                                "tan" => { if let Value::Scalar(n) = args[0] { return Ok(Value::Scalar(n.tan())); } }
                                "tanh" => { if let Value::Scalar(n) = args[0] { return Ok(Value::Scalar(n.tanh())); } }
                                "sinh" => { if let Value::Scalar(n) = args[0] { return Ok(Value::Scalar(n.sinh())); } }
                                "cosh" => { if let Value::Scalar(n) = args[0] { return Ok(Value::Scalar(n.cosh())); } }
                                "asinh" => { if let Value::Scalar(n) = args[0] { return Ok(Value::Scalar(n.asinh())); } }
                                "acosh" => { if let Value::Scalar(n) = args[0] { return Ok(Value::Scalar(n.acosh())); } }
                                "atanh" => { if let Value::Scalar(n) = args[0] { return Ok(Value::Scalar(n.atanh())); } }
                                "sqrt" => { if let Value::Scalar(n) = args[0] { return Ok(Value::Scalar(n.sqrt())); } }
                                "abs" => { if let Value::Scalar(n) = args[0] { return Ok(Value::Scalar(n.abs())); } }
                                "log" => { if let Value::Scalar(n) = args[0] { return Ok(Value::Scalar(n.ln())); } }
                                "log10" => { if let Value::Scalar(n) = args[0] { return Ok(Value::Scalar(n.log10())); } }
                                _ => {}
                            }
                        }
                        return PythonBridge::call_runtime_func(&name, args, nargout).map_err(|e| e.to_string());
                    }
                    "clc" => {
                        println!("\x1B[2J\x1B[1;1H");
                        Ok(Value::Void)
                    }
                    "clear" => {
                        // Dummy clear for now
                        Ok(Value::Void)
                    }
                    "close" => {
                        let _ = PythonBridge::call_runtime_func("close", args, nargout);
                        Ok(Value::Void)
                    }
                    "tic" => {
                        self.tic_time = Some(Instant::now());
                        Ok(Value::Void)
                    }
                    "toc" => {
                        if let Some(start) = self.tic_time {
                            let elapsed = start.elapsed().as_secs_f64();
                            return Ok(Value::Scalar(elapsed));
                        }
                        Ok(Value::Void)
                    }
                    "pause" => {
                        if args.len() == 1 {
                            if let Value::Scalar(n) = args[0] {
                                std::thread::sleep(std::time::Duration::from_secs_f64(n));
                            }
                        }
                        Ok(Value::Void)
                    }
                    "hold" => Ok(Value::Void),
                    "grid" => Ok(Value::Void),
                    "title" => Ok(Value::Void),
                    "xlabel" => Ok(Value::Void),
                    "ylabel" => Ok(Value::Void),
                    "legend" => Ok(Value::Void),
                    "subplot" => Ok(Value::Void),
                    "axis" => Ok(Value::Void),
                    "xlim" => Ok(Value::Void),
                    "ylim" => Ok(Value::Void),
                    "figure" => Ok(Value::Void),
                    _ => {
                        if let Some(path) = self.find_m_file(&name) {
                            let content = fs::read_to_string(path).map_err(|e| e.to_string())?;
                            let program = crate::parser::parse_unilab(&content).map_err(|e| e.to_string())?;
                            if let Some(Stmt::FunctionDef { name: _, params, returns, body }) = program.statements.first() {
                                let parent_env = self.env.clone();
                                let new_env = Arc::new(RwLock::new(Environment::with_parent(parent_env)));
                                for (i, p_name) in params.iter().enumerate() {
                                    if i < args.len() {
                                        new_env.write().unwrap().define(p_name.clone(), args[i].clone());
                                    }
                                }
                                new_env.write().unwrap().define("nargin".to_string(), Value::Scalar(args.len() as f64));
                                new_env.write().unwrap().define("nargout".to_string(), Value::Scalar(nargout.max(1) as f64));
                                new_env.write().unwrap().define("varargin".to_string(), Value::CellArray(args.clone()));
                                let old_env = std::mem::replace(&mut self.env, new_env);
                                let _ = self.eval_block(body)?;
                                
                                let mut res_vals = Vec::new();
                                if returns.len() == 1 && returns[0] == "varargout" {
                                    if let Some(Value::CellArray(v)) = self.env.read().unwrap().get("varargout") {
                                        res_vals = v;
                                    }
                                } else {
                                    let limit = nargout.max(1);
                                    for (i, ret_name) in returns.iter().enumerate() {
                                        if i < limit {
                                            res_vals.push(self.env.read().unwrap().get(ret_name).unwrap_or(Value::Void));
                                        }
                                    }
                                }

                                self.env = old_env;
                                if res_vals.is_empty() {
                                    return Ok(Value::Void);
                                } else if res_vals.len() == 1 {
                                    return Ok(res_vals[0].clone());
                                } else {
                                    return Ok(Value::List(res_vals));
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
                        Value::Scalar(i) => return Ok(Value::Scalar(m.as_slice().unwrap()[*i as usize - 1])),
                        Value::Matrix(indices) => {
                            for &idx_val in indices {
                                res_data.push(m.as_slice().unwrap()[idx_val as usize - 1]);
                            }
                            if indices.len() == 1 {
                                return Ok(Value::Scalar(res_data[0]));
                            }
                            // MATLAB Rule: If source is a vector, result inherits source's orientation
                            let shape = if m.nrows() == 1 {
                                (1, indices.len())
                            } else if m.ncols() == 1 {
                                (indices.len(), 1)
                            } else {
                                (indices.nrows(), indices.ncols())
                            };
                            return Ok(Value::Matrix(Array2::from_shape_vec(shape, res_data).unwrap()));
                        }
                        Value::LogicalMatrix(mask) => {
                            let flat_m = m.as_slice().unwrap();
                            for (i, &b) in mask.iter().enumerate() {
                                if b {
                                    res_data.push(flat_m[i]);
                                }
                            }
                            let len = res_data.len();
                            return Ok(Value::Matrix(Array2::from_shape_vec((len, 1), res_data).unwrap()));
                        }
                        Value::Colon => {
                            let data = m.iter().cloned().collect();
                            return Ok(Value::Matrix(Array2::from_shape_vec((m.len(), 1), data).unwrap()));
                        }
                        _ => return Err("Invalid index type".to_string()),
                    }
                } else if args.len() == 2 {
                    let rows_idx: Vec<usize> = match &args[0] {
                        Value::Scalar(r) => vec![*r as usize - 1],
                        Value::Matrix(mat) => mat.iter().map(|&r| r as usize - 1).collect(),
                        Value::LogicalMatrix(mat) => {
                            mat.iter().enumerate().filter(|&(_, &b)| b).map(|(i, _)| i).collect()
                        }
                        Value::CellArray(v) => v.iter().map(|v| match v {
                            Value::Scalar(s) => Ok(*s as usize - 1),
                            _ => Err("Invalid index in CellArray".to_string()),
                        }).collect::<Result<Vec<usize>, String>>()?,
                        Value::Colon => (0..m.nrows()).collect(),
                        _ => return Err(format!("Invalid row index type: {:?}", args[0])),
                    };
                    let cols_idx: Vec<usize> = match &args[1] {
                        Value::Scalar(c) => vec![*c as usize - 1],
                        Value::Matrix(mat) => mat.iter().map(|&c| c as usize - 1).collect(),
                        Value::LogicalMatrix(mat) => {
                            mat.iter().enumerate().filter(|&(_, &b)| b).map(|(i, _)| i).collect()
                        }
                        Value::CellArray(v) => v.iter().map(|v| match v {
                            Value::Scalar(s) => Ok(*s as usize - 1),
                            _ => Err("Invalid index in CellArray".to_string()),
                        }).collect::<Result<Vec<usize>, String>>()?,
                        Value::Colon => (0..m.ncols()).collect(),
                        _ => return Err(format!("Invalid col index type: {:?}", args[1])),
                    };
                    
                    for &ri in &rows_idx {
                        for &ci in &cols_idx {
                            res_data.push(m[[ri, ci]]);
                        }
                    }
                    if rows_idx.len() == 1 && cols_idx.len() == 1 {
                        return Ok(Value::Scalar(res_data[0]));
                    }
                    return Ok(Value::Matrix(Array2::from_shape_vec((rows_idx.len(), cols_idx.len()), res_data).unwrap()));
                }
                Err("Invalid matrix indexing".to_string())
            }
            Value::ComplexMatrix(m) => {
                 let mut res_data = Vec::new();
                 if args.len() == 2 {
                     let rows_idx: Vec<usize> = match &args[0] {
                         Value::Scalar(r) => vec![*r as usize - 1],
                         Value::Matrix(mat) => mat.iter().map(|&r| r as usize - 1).collect(),
                         Value::LogicalMatrix(mat) => {
                             mat.iter().enumerate().filter(|&(_, &b)| b).map(|(i, _)| i).collect()
                         }
                         Value::Colon => (0..m.nrows()).collect(),
                         _ => return Err("Invalid row index".to_string()),
                     };
                     let cols_idx: Vec<usize> = match &args[1] {
                         Value::Scalar(c) => vec![*c as usize - 1],
                         Value::Matrix(mat) => mat.iter().map(|&c| c as usize - 1).collect(),
                         Value::LogicalMatrix(mat) => {
                             mat.iter().enumerate().filter(|&(_, &b)| b).map(|(i, _)| i).collect()
                         }
                         Value::Colon => (0..m.ncols()).collect(),
                         _ => return Err("Invalid col index".to_string()),
                     };
                     for &ri in &rows_idx {
                         for &ci in &cols_idx {
                             res_data.push(m[[ri, ci]]);
                         }
                     }
                     return Ok(Value::ComplexMatrix(Array2::from_shape_vec((rows_idx.len(), cols_idx.len()), res_data).unwrap()));
                 } else if args.len() == 1 {
                     match &args[0] {
                         Value::Scalar(i) => {
                             let res = m.as_slice().unwrap()[*i as usize - 1];
                             return Ok(Value::Complex(res.re, res.im));
                         }
                         Value::Matrix(indices) => {
                             for &idx_val in indices {
                                 res_data.push(m.as_slice().unwrap()[idx_val as usize - 1]);
                             }
                             if indices.len() == 1 {
                                 let res = res_data[0];
                                 return Ok(Value::Complex(res.re, res.im));
                             }
                             // MATLAB Rule: If source is a vector, result inherits source's orientation
                             let shape = if m.nrows() == 1 {
                                 (1, indices.len())
                             } else if m.ncols() == 1 {
                                 (indices.len(), 1)
                             } else {
                                 (indices.nrows(), indices.ncols())
                             };
                             return Ok(Value::ComplexMatrix(Array2::from_shape_vec(shape, res_data).unwrap()));
                         }
                         Value::LogicalMatrix(mask) => {
                             let flat_m = m.as_slice().unwrap();
                             for (i, &b) in mask.iter().enumerate() {
                                 if b {
                                     res_data.push(flat_m[i]);
                                 }
                             }
                             let len = res_data.len();
                             return Ok(Value::ComplexMatrix(Array2::from_shape_vec((len, 1), res_data).unwrap()));
                         }
                         Value::Colon => {
                             let data = m.iter().cloned().collect();
                             return Ok(Value::ComplexMatrix(Array2::from_shape_vec((m.len(), 1), data).unwrap()));
                         }
                         _ => return Err("Invalid index type".to_string()),
                     }
                 }
                 Err("Invalid complex matrix indexing".to_string())
            }
            Value::CellArray(v) => {
                if args.len() == 1 {
                    match &args[0] {
                        Value::Scalar(i) => {
                            let idx = *i as usize - 1;
                            if idx < v.len() {
                                return Ok(v[idx].clone());
                            }
                        }
                        Value::Matrix(indices) => {
                            let mut res = Vec::new();
                            for &idx_val in indices {
                                res.push(v[idx_val as usize - 1].clone());
                            }
                            return Ok(Value::CellArray(res));
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
