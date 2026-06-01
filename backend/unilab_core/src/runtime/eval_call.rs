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
                new_env.write().unwrap().define("varargin".to_string(), Value::CellArray(args.clone()));
                
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
                        if args.len() >= 1 {
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
                            } else {
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
                            match &args[0] {
                                Value::Matrix(m) => {
                                    let res = vec![m.nrows() as f64, m.ncols() as f64];
                                    return Ok(Value::Matrix(Array2::from_shape_vec((1, 2), res).unwrap()));
                                }
                                Value::ComplexMatrix(m) => {
                                    let res = vec![m.nrows() as f64, m.ncols() as f64];
                                    return Ok(Value::Matrix(Array2::from_shape_vec((1, 2), res).unwrap()));
                                }
                                _ => return Ok(Value::Matrix(Array2::from_elem((1, 2), 1.0))),
                            }
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
                    "sin" | "cos" | "tan" | "tanh" | "exp" | "log" | "log10" | "sqrt" | "abs" |
                    "rand" | "randn" | "randperm" | "reshape" | "linspace" | "zeros" | "ones" | "eye" |
                    "factorial" | "trapz" | "inv" | "eig" | "diag" | "norm" | "det" => {
                        if args.len() == 1 {
                            match name.as_str() {
                                "exp" => { if let Value::Scalar(n) = args[0] { return Ok(Value::Scalar(n.exp())); } }
                                "sin" => { if let Value::Scalar(n) = args[0] { return Ok(Value::Scalar(n.sin())); } }
                                "cos" => { if let Value::Scalar(n) = args[0] { return Ok(Value::Scalar(n.cos())); } }
                                "tan" => { if let Value::Scalar(n) = args[0] { return Ok(Value::Scalar(n.tan())); } }
                                "tanh" => { if let Value::Scalar(n) = args[0] { return Ok(Value::Scalar(n.tanh())); } }
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
                            println!("Elapsed time is {:.6} seconds.", elapsed);
                            Ok(Value::Scalar(elapsed))
                        } else {
                            Err("toc called without tic".to_string())
                        }
                    }
                    "pause" => {
                        if args.len() == 1 {
                            if let Value::Scalar(n) = args[0] {
                                std::thread::sleep(std::time::Duration::from_secs_f64(n));
                            }
                        }
                        Ok(Value::Void)
                    }
                    "hold" | "grid" | "title" | "xlabel" | "ylabel" | "legend" | "subplot" | "axis" | "xlim" | "ylim" | "figure" | "imagesc" | "colorbar" | "colormap" => Ok(Value::Void),
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
                                    for ret_name in returns {
                                        res_vals.push(self.env.read().unwrap().get(ret_name).unwrap_or(Value::Void));
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
                            return Ok(Value::Matrix(Array2::from_shape_vec(indices.raw_dim(), res_data).unwrap()));
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
                         Value::Colon => (0..m.nrows()).collect(),
                         _ => return Err("Invalid row index".to_string()),
                     };
                     let cols_idx: Vec<usize> = match &args[1] {
                         Value::Scalar(c) => vec![*c as usize - 1],
                         Value::Matrix(mat) => mat.iter().map(|&c| c as usize - 1).collect(),
                         Value::Colon => (0..m.ncols()).collect(),
                         _ => return Err("Invalid col index".to_string()),
                     };
                     for &ri in &rows_idx {
                         for &ci in &cols_idx {
                             res_data.push(m[[ri, ci]]);
                         }
                     }
                     if rows_idx.len() == 1 && cols_idx.len() == 1 {
                         let r = res_data[0];
                         return Ok(Value::Complex(r.re, r.im));
                     }
                     return Ok(Value::ComplexMatrix(Array2::from_shape_vec((rows_idx.len(), cols_idx.len()), res_data).unwrap()));
                 } else if args.len() == 1 {
                     match &args[0] {
                         Value::Scalar(i) => {
                             let r = m.as_slice().unwrap()[*i as usize - 1];
                             return Ok(Value::Complex(r.re, r.im));
                         }
                         Value::Matrix(indices) => {
                             for &idx_val in indices {
                                 res_data.push(m.as_slice().unwrap()[idx_val as usize - 1]);
                             }
                             if indices.len() == 1 {
                                 let r = res_data[0];
                                 return Ok(Value::Complex(r.re, r.im));
                             }
                             return Ok(Value::ComplexMatrix(Array2::from_shape_vec(indices.raw_dim(), res_data).unwrap()));
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
                    if let Value::Scalar(i) = &args[0] {
                        let idx = *i as usize - 1;
                        if idx < v.len() {
                            return Ok(v[idx].clone());
                        }
                    }
                }
                Err("Invalid cell array indexing".to_string())
            }
            Value::String(s) => {
                if args.len() == 1 {
                    if let Value::Scalar(i) = &args[0] {
                        let idx = *i as usize - 1;
                        if idx < s.len() {
                            return Ok(Value::String(s.chars().nth(idx).unwrap().to_string()));
                        }
                    }
                }
                Err("Invalid string indexing".to_string())
            }
            Value::Scalar(_) | Value::Complex(_, _) | Value::Bool(_) | Value::Void => {
                Err(format!("Cannot call {:?}", func))
            }
            _ => Err(format!("Function call not yet implemented for: {:?}", func)),
        }
    }
