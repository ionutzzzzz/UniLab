pub mod ast;

use pest::Parser;
use pest_derive::Parser;
use crate::parser::ast::*;

#[derive(Parser)]
#[grammar = "parser/unilab.pest"]
pub struct UniLabParser;

pub fn parse_unilab(input: &str) -> Result<Program, Box<dyn std::error::Error>> {
    let pairs = UniLabParser::parse(Rule::start, input)?;
    
    let mut statements = Vec::new();
    
    for pair in pairs {
        if pair.as_rule() == Rule::start {
            for inner in pair.into_inner() {
                match inner.as_rule() {
                    Rule::stmt_sep | Rule::stmt_no_sep => {
                        if let Some(stmt) = parse_statement(inner.into_inner().next().unwrap()) {
                            statements.push(stmt);
                        }
                    }
                    _ => {}
                }
            }
        }
    }
    
    Ok(Program { statements })
}

fn parse_statement(pair: pest::iterators::Pair<Rule>) -> Option<Stmt> {
    let pair = if pair.as_rule() == Rule::statement {
        pair.into_inner().next().unwrap()
    } else {
        pair
    };

    match pair.as_rule() {
        Rule::assignment => {
            let inner = pair.into_inner().next().unwrap();
            match inner.as_rule() {
                Rule::multi_assignment => {
                    let mut inner = inner.into_inner();
                    let lhs_list = inner.next().unwrap();
                    let rhs_expr = parse_expression(inner.next().unwrap());
                    
                    let mut lhs = Vec::new();
                    for item in lhs_list.into_inner() {
                        lhs.push(parse_expression(item));
                    }
                    
                    Some(Stmt::Assignment { lhs, rhs: rhs_expr })
                }
                Rule::single_assignment => {
                    let mut inner = inner.into_inner();
                    let lhs_expr = parse_expression(inner.next().unwrap());
                    let rhs_expr = parse_expression(inner.next().unwrap());
                    Some(Stmt::Assignment { lhs: vec![lhs_expr], rhs: rhs_expr })
                }
                _ => None
            }
        }
        Rule::expression => Some(Stmt::Expression(parse_expression(pair))),
        Rule::if_stmt => {
            let mut inner = pair.into_inner();
            let condition = parse_expression(inner.next().unwrap());
            
            // Skip separators to find block
            let then_block = loop {
                let next = inner.next().unwrap();
                if next.as_rule() == Rule::block {
                    break parse_block(next);
                }
            };
            
            let mut elseif_clauses = Vec::new();
            let mut else_block = None;
            
            while let Some(next) = inner.next() {
                match next.as_rule() {
                    Rule::elseif_clause => {
                        let mut sub = next.into_inner();
                        let cond = parse_expression(sub.next().unwrap());
                        let block = loop {
                            let s = sub.next().unwrap();
                            if s.as_rule() == Rule::block {
                                break parse_block(s);
                            }
                        };
                        elseif_clauses.push((cond, block));
                    }
                    Rule::else_clause => {
                        let mut sub = next.into_inner();
                        else_block = Some(loop {
                            let s = sub.next().unwrap();
                            if s.as_rule() == Rule::block {
                                break parse_block(s);
                            }
                        });
                    }
                    _ => {}
                }
            }
            
            Some(Stmt::If { condition, then_block, elseif_clauses, else_block })
        }
        Rule::for_stmt => {
            let mut inner = pair.into_inner();
            let var = inner.next().unwrap().as_str().trim().to_string();
            let iter = parse_expression(inner.next().unwrap());
            let body = loop {
                let next = inner.next().unwrap();
                if next.as_rule() == Rule::block {
                    break parse_block(next);
                }
            };
            Some(Stmt::For { var, iter, body })
        }
        Rule::while_stmt => {
            let mut inner = pair.into_inner();
            let condition = parse_expression(inner.next().unwrap());
            let body = loop {
                let next = inner.next().unwrap();
                if next.as_rule() == Rule::block {
                    break parse_block(next);
                }
            };
            Some(Stmt::While { condition, body })
        }
        Rule::function_def => {
            let mut inner = pair.into_inner();
            let mut returns = Vec::new();
            
            let mut current = inner.next().unwrap();
            if current.as_rule() == Rule::function_ret {
                let ret_inner = current.into_inner().next().unwrap();
                match ret_inner.as_rule() {
                    Rule::identifier => returns.push(ret_inner.as_str().trim().to_string()),
                    Rule::lhs_list => {
                        for id_pair in ret_inner.into_inner() {
                            returns.push(id_pair.as_str().trim().to_string());
                        }
                    }
                    _ => {}
                }
                current = inner.next().unwrap();
            }
            
            let name = current.as_str().trim().to_string();
            let mut params = Vec::new();
            
            current = inner.next().unwrap();
            if current.as_rule() == Rule::func_params {
                for p in current.into_inner() {
                    params.push(p.as_str().trim().to_string());
                }
                current = inner.next().unwrap();
            }
            
            let body = parse_block(current);
            
            Some(Stmt::FunctionDef { name, params, returns, body })
        }
        Rule::clear_stmt => {
            let vars = pair.into_inner().map(|p| p.as_str().trim().to_string()).collect();
            Some(Stmt::Clear(vars))
        }
        Rule::global_stmt => {
            let vars = pair.into_inner().map(|p| p.as_str().trim().to_string()).collect();
            Some(Stmt::Global(vars))
        }
        Rule::return_stmt => Some(Stmt::Return),
        Rule::break_stmt => Some(Stmt::Break),
        Rule::continue_stmt => Some(Stmt::Continue),
        Rule::command_call => {
            let mut inner = pair.into_inner();
            let command = inner.next().unwrap().as_str().trim().to_string();
            let args = inner.map(|p| p.as_str().trim().to_string()).collect();
            Some(Stmt::CommandCall { command, args })
        }
        _ => None
    }
}

fn parse_block(pair: pest::iterators::Pair<Rule>) -> Vec<Stmt> {
    let mut statements = Vec::new();
    for inner in pair.into_inner() {
        match inner.as_rule() {
            Rule::stmt_sep | Rule::stmt_no_sep => {
                if let Some(stmt) = parse_statement(inner.into_inner().next().unwrap()) {
                    statements.push(stmt);
                }
            }
            _ => {}
        }
    }
    statements
}

fn parse_expression(pair: pest::iterators::Pair<Rule>) -> Expr {
    match pair.as_rule() {
        Rule::expression => parse_expression(pair.into_inner().next().unwrap()),
        Rule::logical_or => parse_logical_or(pair),
        Rule::logical_and => parse_logical_and(pair),
        Rule::comparison => parse_comparison(pair),
        Rule::range_expr => parse_range_expr(pair),
        Rule::addition => parse_addition(pair),
        Rule::multiplication => parse_multiplication(pair),
        Rule::unary => parse_unary(pair),
        Rule::power => parse_power(pair),
        Rule::postfix_expr => parse_postfix_expr(pair),
        Rule::atom => parse_atom(pair),
        Rule::anonymous_func => {
            let mut sub = pair.into_inner();
            let mut params = Vec::new();
            let mut next = sub.next().unwrap();
            if next.as_rule() == Rule::func_params {
                params = next.into_inner().map(|p| p.as_str().trim().to_string()).collect();
                next = sub.next().unwrap();
            }
            Expr::AnonymousFunc { params, body: Box::new(parse_expression(next)) }
        }
        _ => Expr::Identifier(pair.as_str().trim().to_string())
    }
}

fn parse_logical_or(pair: pest::iterators::Pair<Rule>) -> Expr {
    let mut inner = pair.into_inner();
    let mut res = parse_expression(inner.next().unwrap());
    while let Some(op_pair) = inner.next() {
        let op = match op_pair.as_str() {
            "||" => BinaryOperator::ShortOr,
            "|" => BinaryOperator::Or,
            _ => unreachable!(),
        };
        let right = parse_expression(inner.next().unwrap());
        res = Expr::BinaryOp(Box::new(res), op, Box::new(right));
    }
    res
}

fn parse_logical_and(pair: pest::iterators::Pair<Rule>) -> Expr {
    let mut inner = pair.into_inner();
    let mut res = parse_expression(inner.next().unwrap());
    while let Some(op_pair) = inner.next() {
        let op = match op_pair.as_str() {
            "&&" => BinaryOperator::ShortAnd,
            "&" => BinaryOperator::And,
            _ => unreachable!(),
        };
        let right = parse_expression(inner.next().unwrap());
        res = Expr::BinaryOp(Box::new(res), op, Box::new(right));
    }
    res
}

fn parse_comparison(pair: pest::iterators::Pair<Rule>) -> Expr {
    let mut inner = pair.into_inner();
    let mut res = parse_expression(inner.next().unwrap());
    while let Some(op_pair) = inner.next() {
        let op = match op_pair.as_str() {
            "==" => BinaryOperator::Eq,
            "~=" => BinaryOperator::Ne,
            ">" => BinaryOperator::Gt,
            "<" => BinaryOperator::Lt,
            ">=" => BinaryOperator::Ge,
            "<=" => BinaryOperator::Le,
            _ => unreachable!(),
        };
        let right = parse_expression(inner.next().unwrap());
        res = Expr::BinaryOp(Box::new(res), op, Box::new(right));
    }
    res
}

fn parse_range_expr(pair: pest::iterators::Pair<Rule>) -> Expr {
    let mut inner = pair.into_inner();
    let first = parse_expression(inner.next().unwrap());
    if let Some(next) = inner.next() {
        let second = parse_expression(next);
        if let Some(third) = inner.next() {
            let third = parse_expression(third);
            Expr::FunctionCall { func: Box::new(Expr::Identifier("range".to_string())), args: vec![first, second, third] }
        } else {
            Expr::FunctionCall { func: Box::new(Expr::Identifier("range".to_string())), args: vec![first, second] }
        }
    } else {
        first
    }
}

fn parse_addition(pair: pest::iterators::Pair<Rule>) -> Expr {
    let mut inner = pair.into_inner();
    let mut res = parse_expression(inner.next().unwrap());
    while let Some(op_pair) = inner.next() {
        let op = match op_pair.as_str() {
            "+" => BinaryOperator::Add,
            "-" => BinaryOperator::Sub,
            ".+" => BinaryOperator::DotAdd,
            ".-" => BinaryOperator::DotSub,
            _ => unreachable!(),
        };
        let right = parse_expression(inner.next().unwrap());
        res = Expr::BinaryOp(Box::new(res), op, Box::new(right));
    }
    res
}

fn parse_multiplication(pair: pest::iterators::Pair<Rule>) -> Expr {
    let mut inner = pair.into_inner();
    let mut res = parse_expression(inner.next().unwrap());
    while let Some(op_pair) = inner.next() {
        let op = match op_pair.as_str() {
            "*" => BinaryOperator::Mul,
            "/" => BinaryOperator::Div,
            "\\" => BinaryOperator::LDiv,
            ".*" => BinaryOperator::DotMul,
            "./" => BinaryOperator::DotDiv,
            ".\\" => BinaryOperator::DotLDiv,
            _ => unreachable!(),
        };
        let right = parse_expression(inner.next().unwrap());
        res = Expr::BinaryOp(Box::new(res), op, Box::new(right));
    }
    res
}

fn parse_unary(pair: pest::iterators::Pair<Rule>) -> Expr {
    let mut inner = pair.into_inner();
    let first = inner.next().unwrap();
    if first.as_rule() == Rule::unary_op {
        let op = match first.as_str() {
            "+" => UnaryOperator::Plus,
            "-" => UnaryOperator::Minus,
            "~" => UnaryOperator::Not,
            _ => unreachable!(),
        };
        Expr::UnaryOp(op, Box::new(parse_expression(inner.next().unwrap())))
    } else {
        parse_expression(first)
    }
}

fn parse_power(pair: pest::iterators::Pair<Rule>) -> Expr {
    let mut inner = pair.into_inner();
    let mut res = parse_expression(inner.next().unwrap());
    while let Some(op_pair) = inner.next() {
        let op = match op_pair.as_str() {
            "^" => BinaryOperator::Pow,
            ".^" => BinaryOperator::DotPow,
            _ => unreachable!(),
        };
        let right = parse_expression(inner.next().unwrap());
        res = Expr::BinaryOp(Box::new(res), op, Box::new(right));
    }
    res
}

fn parse_postfix_expr(pair: pest::iterators::Pair<Rule>) -> Expr {
    let mut inner = pair.into_inner();
    let first = inner.next().unwrap();
    let mut res = parse_expression(first);
    while let Some(op_pair) = inner.next() {
        let op = op_pair.into_inner().next().expect("postfix_op should have a child");
        match op.as_rule() {
            Rule::function_call => {
                let mut args = Vec::new();
                if let Some(args_pair) = op.into_inner().next() {
                    for arg in args_pair.into_inner() {
                        args.push(parse_arg_item(arg));
                    }
                }
                res = Expr::FunctionCall { func: Box::new(res), args };
            }
            Rule::cell_indexing => {
                let mut args = Vec::new();
                if let Some(args_pair) = op.into_inner().next() {
                    for arg in args_pair.into_inner() {
                        args.push(parse_arg_item(arg));
                    }
                }
                res = Expr::CellIndexing { target: Box::new(res), args };
            }
            Rule::transpose => res = Expr::Transpose(Box::new(res)),
            Rule::attr_access => {
                let op_str = op.as_str().to_string();
                let property = op.into_inner()
                    .filter(|p| p.as_rule() == Rule::identifier)
                    .map(|p| p.as_str().trim().to_string())
                    .next()
                    .expect(&format!("Missing identifier in property access: {:?}", op_str));
                res = Expr::PropertyAccess { target: Box::new(res), property };
            }
            _ => unreachable!("Unexpected rule in postfix_op: {:?}", op.as_rule()),
        }
    }
    res
}

fn parse_atom(pair: pest::iterators::Pair<Rule>) -> Expr {
    let mut inner = pair.into_inner();
    let first = inner.next().unwrap();
    match first.as_rule() {
        Rule::number => {
            let s = first.as_str().trim();
            if s.ends_with('i') || s.ends_with('j') {
                let val = s[..s.len()-1].parse::<f64>().unwrap_or(1.0);
                Expr::Complex(0.0, val)
            } else {
                Expr::Number(s.parse().unwrap())
            }
        }
        Rule::string => Expr::String(first.as_str()[1..first.as_str().len()-1].replace("''", "'")),
        Rule::identifier => Expr::Identifier(first.as_str().trim().to_string()),
        Rule::matrix => {
            let mut matrix = Vec::new();
            for row_pair in first.into_inner() {
                if row_pair.as_rule() == Rule::row {
                    matrix.push(row_pair.into_inner().map(parse_expression).collect());
                }
            }
            Expr::Matrix(matrix)
        }
        Rule::cell_array => {
            let mut cell_array = Vec::new();
            for row_pair in first.into_inner() {
                if row_pair.as_rule() == Rule::row {
                    cell_array.push(row_pair.into_inner().map(parse_expression).collect());
                }
            }
            Expr::CellArray(cell_array)
        }
        Rule::function_handle => Expr::FunctionHandle(first.into_inner().next().unwrap().as_str().trim().to_string()),
        Rule::expression => parse_expression(first),
        Rule::end_kw => Expr::End,
        _ => Expr::Identifier(first.as_str().trim().to_string()),
    }
}

fn parse_arg_item(pair: pest::iterators::Pair<Rule>) -> Expr {
    let mut inner = pair.clone().into_inner();
    let first = inner.next().unwrap();
    match first.as_rule() {
        Rule::expression => parse_expression(first),
        Rule::colon_arg => Expr::Colon,
        Rule::keyword_arg => {
            let mut sub = first.into_inner();
            let key = sub.next().unwrap().as_str().trim().to_string();
            let val = parse_expression(sub.next().unwrap());
            Expr::BinaryOp(Box::new(Expr::Identifier(key)), BinaryOperator::Eq, Box::new(val))
        }
        _ => Expr::Identifier(pair.as_str().trim().to_string()),
    }
}

fn parse_expr_item(pair: pest::iterators::Pair<Rule>) -> Option<Expr> {
    match pair.as_rule() {
        Rule::identifier => Some(Expr::Identifier(pair.as_str().trim().to_string())),
        Rule::unary_op => None,
        _ => Some(parse_expression(pair)),
    }
}
