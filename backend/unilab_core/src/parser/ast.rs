use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum BinaryOperator {
    Add, Sub, DotAdd, DotSub,
    Mul, Div, LDiv, DotMul, DotDiv, DotLDiv,
    Pow, DotPow,
    Eq, Ne, Gt, Lt, Ge, Le,
    And, Or, ShortAnd, ShortOr,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum UnaryOperator {
    Plus, Minus, Not,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum Expr {
    Number(f64),
    Complex(f64, f64),
    String(String),
    Identifier(String),
    End,
    Colon,
    Matrix(Vec<Vec<Expr>>),
    CellArray(Vec<Vec<Expr>>),
    BinaryOp(Box<Expr>, BinaryOperator, Box<Expr>),
    UnaryOp(UnaryOperator, Box<Expr>),
    FunctionCall {
        func: Box<Expr>,
        args: Vec<Expr>,
    },
    CellIndexing {
        target: Box<Expr>,
        args: Vec<Expr>,
    },
    PropertyAccess {
        target: Box<Expr>,
        property: String,
    },
    Transpose(Box<Expr>),
    AnonymousFunc {
        params: Vec<String>,
        body: Box<Expr>,
    },
    FunctionHandle(String),
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum Stmt {
    Expression(Expr),
    Assignment {
        lhs: Vec<Expr>,
        rhs: Expr,
    },
    If {
        condition: Expr,
        then_block: Vec<Stmt>,
        elseif_clauses: Vec<(Expr, Vec<Stmt>)>,
        else_block: Option<Vec<Stmt>>,
    },
    For {
        var: String,
        iter: Expr,
        body: Vec<Stmt>,
    },
    While {
        condition: Expr,
        body: Vec<Stmt>,
    },
    Switch {
        expression: Expr,
        cases: Vec<(Expr, Vec<Stmt>)>,
        otherwise: Option<Vec<Stmt>>,
    },
    Try {
        try_block: Vec<Stmt>,
        catch_var: Option<String>,
        catch_block: Vec<Stmt>,
    },
    FunctionDef {
        name: String,
        params: Vec<String>,
        returns: Vec<String>,
        body: Vec<Stmt>,
    },
    Clear(Vec<String>),
    Global(Vec<String>),
    Return,
    Break,
    Continue,
    Import(String),
    Export(String),
    CommandCall {
        command: String,
        args: Vec<String>,
    },
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct Program {
    pub statements: Vec<Stmt>,
}
