use ndarray::Array2;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fmt;
use std::sync::Arc;
use crate::parser::ast::{Expr, Stmt};
use num_complex::Complex64;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum Value {
    Scalar(f64),
    Complex(f64, f64),
    Matrix(Arc<Array2<f64>>),
    ComplexMatrix(Arc<Array2<Complex64>>),
    LogicalMatrix(Arc<Array2<bool>>),
    String(Arc<String>),
    Bool(bool),
    CellArray(Arc<Vec<Value>>),
    Struct(Arc<HashMap<String, Value>>),
    FunctionHandle(String),
    Function {
        name: String,
        params: Vec<String>,
        returns: Vec<String>,
        body: Arc<Vec<Stmt>>,
    },
    AnonymousFunction {
        params: Vec<String>,
        body: Arc<Expr>,
    },
    Void,
    Colon,
    List(Arc<Vec<Value>>),
}

impl Value {
    pub fn is_truthy(&self) -> bool {
        match self {
            Value::Scalar(n) => *n != 0.0 && !n.is_nan(),
            Value::Complex(re, im) => (*re != 0.0 || *im != 0.0) && !re.is_nan() && !im.is_nan(),
            Value::Matrix(m) => !m.is_empty() && m.iter().all(|&x| x != 0.0 && !x.is_nan()),
            Value::ComplexMatrix(m) => {
                !m.is_empty()
                    && m.iter()
                        .all(|&x| (x.re != 0.0 || x.im != 0.0) && !x.re.is_nan() && !x.im.is_nan())
            }
            Value::LogicalMatrix(m) => !m.is_empty() && m.iter().all(|&x| x),
            Value::String(s) => !s.is_empty(),
            Value::Bool(b) => *b,
            Value::CellArray(v) => !v.is_empty(),
            Value::Struct(s) => !s.is_empty(),
            Value::FunctionHandle(_) | Value::Function { .. } | Value::AnonymousFunction { .. } => {
                true
            }
            Value::Void | Value::Colon => false,
            Value::List(l) => !l.is_empty() && l[0].is_truthy(),
        }
    }

    pub fn format_disp(&self) -> String {
        match self {
            Value::String(s) => (**s).clone(),
            other => format!("{}", other),
        }
    }
}

impl fmt::Display for Value {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Value::Scalar(n) => write!(f, "{}", n),
            Value::Complex(re, im) => {
                if *im < 0.0 {
                    write!(f, "{} - {}i", re, -im)
                } else {
                    write!(f, "{} + {}i", re, im)
                }
            }
            Value::Matrix(m) => {
                if m.is_empty() {
                    write!(f, "[]")
                } else if m.len() == 1 {
                    write!(f, "{}", m[[0, 0]])
                } else if m.len() <= 25 {
                    write!(f, "[")?;
                    for (i, row) in m.rows().into_iter().enumerate() {
                        if i > 0 {
                            write!(f, "; ")?;
                        }
                        for (j, &val) in row.into_iter().enumerate() {
                            if j > 0 {
                                write!(f, ", ")?;
                            }
                            write!(f, "{}", val)?;
                        }
                    }
                    write!(f, "]")
                } else {
                    write!(f, "{}x{} matrix", m.nrows(), m.ncols())
                }
            }
            Value::ComplexMatrix(m) => {
                write!(f, "{}x{} complex matrix", m.nrows(), m.ncols())
            }
            Value::LogicalMatrix(m) => {
                if m.is_empty() {
                    write!(f, "[]")
                } else if m.len() <= 25 {
                    write!(f, "[")?;
                    for (i, row) in m.rows().into_iter().enumerate() {
                        if i > 0 {
                            write!(f, "; ")?;
                        }
                        for (j, &val) in row.into_iter().enumerate() {
                            if j > 0 {
                                write!(f, ", ")?;
                            }
                            write!(f, "{}", if val { 1 } else { 0 })?;
                        }
                    }
                    write!(f, "]")
                } else {
                    write!(f, "{}x{} logical matrix", m.nrows(), m.ncols())
                }
            }
            Value::String(s) => write!(f, "'{}'", s),
            Value::Bool(b) => write!(f, "{}", if *b { "true" } else { "false" }),
            Value::CellArray(v) => write!(f, "cell array (len: {})", v.len()),
            Value::Struct(s) => {
                write!(f, "struct with fields: ")?;
                let mut keys: Vec<&String> = s.keys().collect();
                keys.sort();
                for (idx, key) in keys.iter().enumerate() {
                    if idx > 0 {
                        write!(f, ", ")?;
                    }
                    write!(f, "{}", key)?;
                }
                Ok(())
            }
            Value::FunctionHandle(name) => write!(f, "@{}", name),
            Value::Function { name, .. } => write!(f, "function: {}", name),
            Value::AnonymousFunction { .. } => write!(f, "@anonymous"),
            Value::Void => write!(f, "void"),
            Value::Colon => write!(f, ":"),
            Value::List(l) => {
                write!(f, "[")?;
                for (i, v) in l.iter().enumerate() {
                    if i > 0 {
                        write!(f, ", ")?;
                    }
                    write!(f, "{}", v)?;
                }
                write!(f, "]")
            }
        }
    }
}
