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
                        if let Some(stmt) = parse_stmt_wrapper(inner) {
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

fn parse_stmt_wrapper(pair: pest::iterators::Pair<Rule>) -> Option<Stmt> {
    let mut inner = pair.into_inner();
    let stmt_pair = inner.next()?;
    let suppressed = inner
        .find(|p| p.as_rule() == Rule::separator)
        .map(|p| p.as_str() == ";")
        .unwrap_or(false);
    parse_statement(stmt_pair, suppressed)
}

fn parse_statement(pair: pest::iterators::Pair<Rule>, suppressed: bool) -> Option<Stmt> {
    let pair = if pair.as_rule() == Rule::statement {
        pair.into_inner().next()?
    } else {
        pair
    };

    match pair.as_rule() {
        Rule::assignment => {
            let inner = pair.into_inner().next()?;
            match inner.as_rule() {
                Rule::multi_assignment => {
                    let mut inner = inner.into_inner();
                    let lhs_list = inner.next()?;
                    let rhs_expr = parse_expression(inner.next()?);

                    let mut lhs = Vec::new();
                    for item in lhs_list.into_inner() {
                        lhs.push(parse_lhs_item(item));
                    }

                    Some(Stmt::Assignment {
                        lhs,
                        rhs: rhs_expr,
                        suppressed,
                    })
                }
                Rule::single_assignment => {
                    let mut inner = inner.into_inner();
                    let lhs_expr = parse_expression(inner.next()?);
                    let rhs_expr = parse_expression(inner.next()?);
                    Some(Stmt::Assignment {
                        lhs: vec![lhs_expr],
                        rhs: rhs_expr,
                        suppressed,
                    })
                }
                _ => None,
            }
        }
        Rule::expression => Some(Stmt::Expression {
            expr: parse_expression(pair),
            suppressed,
        }),
        Rule::if_stmt => {
            let mut condition_opt = None;
            let mut then_block = Vec::new();
            let mut elseif_clauses = Vec::new();
            let mut else_block = None;

            for child in pair.into_inner() {
                match child.as_rule() {
                    Rule::expression if condition_opt.is_none() => {
                        condition_opt = Some(parse_expression(child));
                    }
                    Rule::block => {
                        then_block = parse_block(child);
                    }
                    Rule::elseif_clause => {
                        let mut ei_cond = None;
                        let mut ei_block = Vec::new();
                        for sub in child.into_inner() {
                            match sub.as_rule() {
                                Rule::expression => ei_cond = Some(parse_expression(sub)),
                                Rule::block => ei_block = parse_block(sub),
                                _ => {}
                            }
                        }
                        if let Some(cond) = ei_cond {
                            elseif_clauses.push((cond, ei_block));
                        }
                    }
                    Rule::else_clause => {
                        for sub in child.into_inner() {
                            if sub.as_rule() == Rule::block {
                                else_block = Some(parse_block(sub));
                            }
                        }
                    }
                    _ => {}
                }
            }

            Some(Stmt::If {
                condition: condition_opt?,
                then_block,
                elseif_clauses,
                else_block,
            })
        }
        Rule::for_stmt => {
            let mut var = None;
            let mut iter = None;
            let mut body = Vec::new();
            for child in pair.into_inner() {
                match child.as_rule() {
                    Rule::identifier if var.is_none() => {
                        var = Some(child.as_str().trim().to_string());
                    }
                    Rule::expression if iter.is_none() => {
                        iter = Some(parse_expression(child));
                    }
                    Rule::block => {
                        body = parse_block(child);
                    }
                    _ => {}
                }
            }
            Some(Stmt::For {
                var: var?,
                iter: iter?,
                body,
            })
        }
        Rule::parfor_stmt => {
            let mut var = None;
            let mut iter = None;
            let mut body = Vec::new();
            for child in pair.into_inner() {
                match child.as_rule() {
                    Rule::identifier if var.is_none() => {
                        var = Some(child.as_str().trim().to_string());
                    }
                    Rule::expression if iter.is_none() => {
                        iter = Some(parse_expression(child));
                    }
                    Rule::block => {
                        body = parse_block(child);
                    }
                    _ => {}
                }
            }
            Some(Stmt::ParFor {
                var: var?,
                iter: iter?,
                body,
            })
        }
        Rule::while_stmt => {
            let mut condition = None;
            let mut body = Vec::new();
            for child in pair.into_inner() {
                match child.as_rule() {
                    Rule::expression if condition.is_none() => {
                        condition = Some(parse_expression(child));
                    }
                    Rule::block => {
                        body = parse_block(child);
                    }
                    _ => {}
                }
            }
            Some(Stmt::While {
                condition: condition?,
                body,
            })
        }
        Rule::switch_stmt => {
            let mut expression = None;
            let mut cases = Vec::new();
            let mut otherwise = None;

            for child in pair.into_inner() {
                match child.as_rule() {
                    Rule::expression if expression.is_none() => {
                        expression = Some(parse_expression(child));
                    }
                    Rule::case_clause => {
                        let mut c_expr = None;
                        let mut c_block = Vec::new();
                        for sub in child.into_inner() {
                            match sub.as_rule() {
                                Rule::expression => c_expr = Some(parse_expression(sub)),
                                Rule::block => c_block = parse_block(sub),
                                _ => {}
                            }
                        }
                        if let Some(expr) = c_expr {
                            cases.push((expr, c_block));
                        }
                    }
                    Rule::otherwise_clause => {
                        for sub in child.into_inner() {
                            if sub.as_rule() == Rule::block {
                                otherwise = Some(parse_block(sub));
                            }
                        }
                    }
                    _ => {}
                }
            }

            Some(Stmt::Switch {
                expression: expression?,
                cases,
                otherwise,
            })
        }
        Rule::try_stmt => {
            let mut try_block = Vec::new();
            let mut catch_var = None;
            let mut catch_block = Vec::new();

            for child in pair.into_inner() {
                match child.as_rule() {
                    Rule::block => {
                        try_block = parse_block(child);
                    }
                    Rule::catch_clause => {
                        for sub in child.into_inner() {
                            match sub.as_rule() {
                                Rule::catch_var => {
                                    if let Some(id) = sub.into_inner().next() {
                                        catch_var = Some(id.as_str().trim().to_string());
                                    }
                                }
                                Rule::block => {
                                    catch_block = parse_block(sub);
                                }
                                _ => {}
                            }
                        }
                    }
                    _ => {}
                }
            }

            Some(Stmt::Try {
                try_block,
                catch_var,
                catch_block,
            })
        }
        Rule::function_def => {
            let mut returns = Vec::new();
            let mut name = None;
            let mut params = Vec::new();
            let mut body = Vec::new();

            for child in pair.into_inner() {
                match child.as_rule() {
                    Rule::function_ret => {
                        if let Some(ret_inner) = child.into_inner().next() {
                            match ret_inner.as_rule() {
                                Rule::identifier => {
                                    returns.push(ret_inner.as_str().trim().to_string());
                                }
                                Rule::func_ret_list => {
                                    for id_pair in ret_inner.into_inner() {
                                        if id_pair.as_rule() == Rule::identifier {
                                            returns.push(id_pair.as_str().trim().to_string());
                                        }
                                    }
                                }
                                _ => {}
                            }
                        }
                    }
                    Rule::identifier if name.is_none() => {
                        name = Some(child.as_str().trim().to_string());
                    }
                    Rule::func_params => {
                        for p in child.into_inner() {
                            params.push(p.as_str().trim().to_string());
                        }
                    }
                    Rule::block => {
                        body = parse_block(child);
                    }
                    _ => {}
                }
            }

            Some(Stmt::FunctionDef {
                name: name?,
                params,
                returns,
                body,
            })
        }
        Rule::clear_stmt => {
            let vars = pair
                .into_inner()
                .filter(|p| p.as_rule() == Rule::identifier)
                .map(|p| p.as_str().trim().to_string())
                .collect();
            Some(Stmt::Clear(vars))
        }
        Rule::global_stmt => {
            let vars = pair
                .into_inner()
                .filter(|p| p.as_rule() == Rule::identifier)
                .map(|p| p.as_str().trim().to_string())
                .collect();
            Some(Stmt::Global(vars))
        }
        Rule::return_stmt => Some(Stmt::Return),
        Rule::break_stmt => Some(Stmt::Break),
        Rule::continue_stmt => Some(Stmt::Continue),
        Rule::import_stmt => {
            let path = pair
                .into_inner()
                .find(|p| p.as_rule() == Rule::import_path)
                .map(|p| p.as_str().trim().to_string())?;
            Some(Stmt::Import(path))
        }
        Rule::export_stmt => {
            let id = pair
                .into_inner()
                .find(|p| p.as_rule() == Rule::identifier)
                .map(|p| p.as_str().trim().to_string())?;
            Some(Stmt::Export(id))
        }
        Rule::command_call => {
            let mut inner = pair.into_inner();
            let command = inner.next()?.as_str().trim().to_string();
            let args = inner
                .map(|p| {
                    if p.as_rule() == Rule::string {
                        unquote_matlab_string(p.as_str())
                    } else {
                        p.as_str().trim().to_string()
                    }
                })
                .collect();
            Some(Stmt::CommandCall { command, args })
        }
        _ => None,
    }
}

fn parse_lhs_item(pair: pest::iterators::Pair<Rule>) -> Expr {
    if pair.as_rule() == Rule::lhs_item {
        if let Some(inner) = pair.into_inner().next() {
            match inner.as_rule() {
                Rule::ignore_arg => Expr::Ignore,
                _ => parse_expression(inner),
            }
        } else {
            Expr::Ignore
        }
    } else if pair.as_rule() == Rule::ignore_arg || pair.as_str().trim() == "~" {
        Expr::Ignore
    } else {
        parse_expression(pair)
    }
}

fn parse_block(pair: pest::iterators::Pair<Rule>) -> Vec<Stmt> {
    let mut statements = Vec::new();
    for inner in pair.into_inner() {
        match inner.as_rule() {
            Rule::stmt_sep | Rule::stmt_no_sep => {
                if let Some(stmt) = parse_stmt_wrapper(inner) {
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
        Rule::expression => {
            if let Some(inner) = pair.into_inner().next() {
                parse_expression(inner)
            } else {
                Expr::Number(f64::NAN)
            }
        }
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
            let first = match sub.next() {
                Some(f) => f,
                None => return Expr::Number(f64::NAN),
            };
            let body_pair = if first.as_rule() == Rule::func_params {
                params = first
                    .into_inner()
                    .map(|p| p.as_str().trim().to_string())
                    .collect();
                match sub.next() {
                    Some(b) => b,
                    None => return Expr::Number(f64::NAN),
                }
            } else {
                first
            };
            Expr::AnonymousFunc {
                params,
                body: Box::new(parse_expression(body_pair)),
            }
        }
        Rule::ignore_arg => Expr::Ignore,
        _ => Expr::Identifier(pair.as_str().trim().to_string()),
    }
}

/// Parses a matrix/cell row while honoring MATLAB's space-sensitive sign rule:
/// `[1 -2]` -> `[1, -2]` (2 elements: whitespace before `-`, no whitespace after `-`),
/// whereas `[1 - 2]` and `[1-2]` -> `[1 - 2]` (1 element).
fn parse_row_items(row_pair: pest::iterators::Pair<Rule>) -> Vec<Expr> {
    let mut items = Vec::new();
    for expr_pair in row_pair.into_inner() {
        items.extend(split_row_expr(expr_pair));
    }
    items
}

fn split_row_expr(pair: pest::iterators::Pair<Rule>) -> Vec<Expr> {
    match pair.as_rule() {
        Rule::expression => {
            if let Some(inner) = pair.into_inner().next() {
                split_row_expr(inner)
            } else {
                Vec::new()
            }
        }
        Rule::logical_or => split_row_binary_chain(pair, |op| match op {
            "||" => BinaryOperator::ShortOr,
            _ => BinaryOperator::Or,
        }),
        Rule::logical_and => split_row_binary_chain(pair, |op| match op {
            "&&" => BinaryOperator::ShortAnd,
            _ => BinaryOperator::And,
        }),
        Rule::comparison => split_row_binary_chain(pair, |op| match op {
            "==" => BinaryOperator::Eq,
            "~=" => BinaryOperator::Ne,
            ">" => BinaryOperator::Gt,
            "<" => BinaryOperator::Lt,
            ">=" => BinaryOperator::Ge,
            _ => BinaryOperator::Le,
        }),
        Rule::range_expr => split_row_range(pair),
        Rule::addition => split_row_addition(pair),
        _ => vec![parse_expression(pair)],
    }
}

fn split_row_binary_chain<F>(pair: pest::iterators::Pair<Rule>, map_op: F) -> Vec<Expr>
where
    F: Fn(&str) -> BinaryOperator,
{
    let mut inner = pair.into_inner();
    let Some(first_pair) = inner.next() else {
        return Vec::new();
    };
    let mut parts = split_row_expr(first_pair);
    let Some(mut acc) = parts.pop() else {
        return Vec::new();
    };
    let mut out = parts;

    while let Some(op_pair) = inner.next() {
        let op = map_op(op_pair.as_str());
        let Some(rhs_pair) = inner.next() else {
            break;
        };
        let mut rhs_parts = split_row_expr(rhs_pair);
        if rhs_parts.is_empty() {
            continue;
        }
        let first_rhs = rhs_parts.remove(0);
        acc = Expr::BinaryOp(Box::new(acc), op, Box::new(first_rhs));
        if !rhs_parts.is_empty() {
            out.push(acc);
            acc = rhs_parts.pop().unwrap();
            out.extend(rhs_parts);
        }
    }

    out.push(acc);
    out
}

fn split_row_range(pair: pest::iterators::Pair<Rule>) -> Vec<Expr> {
    let mut inner = pair.into_inner();
    let Some(first) = inner.next() else {
        return Vec::new();
    };
    let mut p0 = split_row_expr(first);
    let Some(second) = inner.next() else {
        return p0;
    };

    let Some(start_expr) = p0.pop() else {
        return Vec::new();
    };
    let mut out = p0;

    let mut p1 = split_row_expr(second);
    if p1.is_empty() {
        out.push(start_expr);
        return out;
    }

    if let Some(third) = inner.next() {
        let step_expr = p1.remove(0);
        if !p1.is_empty() {
            // Unlikely syntax like `[1:2 -3:4]`; fall back cleanly
            out.push(Expr::FunctionCall {
                func: Box::new(Expr::Identifier("range".to_string())),
                args: vec![start_expr, step_expr],
            });
            out.extend(p1);
            out.extend(split_row_expr(third));
            return out;
        }
        let mut p2 = split_row_expr(third);
        if p2.is_empty() {
            out.push(Expr::FunctionCall {
                func: Box::new(Expr::Identifier("range".to_string())),
                args: vec![start_expr, step_expr],
            });
            return out;
        }
        let stop_expr = p2.remove(0);
        out.push(Expr::FunctionCall {
            func: Box::new(Expr::Identifier("range".to_string())),
            args: vec![start_expr, step_expr, stop_expr],
        });
        out.extend(p2);
        out
    } else {
        let stop_expr = p1.remove(0);
        out.push(Expr::FunctionCall {
            func: Box::new(Expr::Identifier("range".to_string())),
            args: vec![start_expr, stop_expr],
        });
        out.extend(p1);
        out
    }
}

fn split_row_addition(pair: pest::iterators::Pair<Rule>) -> Vec<Expr> {
    let mut inner = pair.into_inner();
    let Some(first_term) = inner.next() else {
        return Vec::new();
    };
    let mut prev_end = first_term.as_span().end();
    let mut curr = parse_expression(first_term);
    let mut out = Vec::new();

    while let Some(op_pair) = inner.next() {
        let op_span = op_pair.as_span();
        let op_str = op_pair.as_str();
        let Some(next_term) = inner.next() else {
            break;
        };
        let next_span = next_term.as_span();
        let next_end = next_span.end();

        let has_space_before = op_span.start() > prev_end;
        let has_space_after = next_span.start() > op_span.end();
        let is_unary_sign = op_str == "+" || op_str == "-";

        if has_space_before && !has_space_after && is_unary_sign {
            out.push(curr);
            let u_op = if op_str == "-" {
                UnaryOperator::Minus
            } else {
                UnaryOperator::Plus
            };
            curr = Expr::UnaryOp(u_op, Box::new(parse_expression(next_term)));
        } else {
            let bin_op = match op_str {
                "+" => BinaryOperator::Add,
                "-" => BinaryOperator::Sub,
                ".+" => BinaryOperator::DotAdd,
                _ => BinaryOperator::DotSub,
            };
            curr = Expr::BinaryOp(Box::new(curr), bin_op, Box::new(parse_expression(next_term)));
        }
        prev_end = next_end;
    }

    out.push(curr);
    out
}

fn parse_logical_or(pair: pest::iterators::Pair<Rule>) -> Expr {
    let mut inner = pair.into_inner();
    let mut res = parse_expression(inner.next().unwrap());
    while let Some(op_pair) = inner.next() {
        let op = match op_pair.as_str() {
            "||" => BinaryOperator::ShortOr,
            "|" => BinaryOperator::Or,
            _ => BinaryOperator::Or,
        };
        if let Some(rhs) = inner.next() {
            res = Expr::BinaryOp(Box::new(res), op, Box::new(parse_expression(rhs)));
        }
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
            _ => BinaryOperator::And,
        };
        if let Some(rhs) = inner.next() {
            res = Expr::BinaryOp(Box::new(res), op, Box::new(parse_expression(rhs)));
        }
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
            _ => BinaryOperator::Eq,
        };
        if let Some(rhs) = inner.next() {
            res = Expr::BinaryOp(Box::new(res), op, Box::new(parse_expression(rhs)));
        }
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
            Expr::FunctionCall {
                func: Box::new(Expr::Identifier("range".to_string())),
                args: vec![first, second, third],
            }
        } else {
            Expr::FunctionCall {
                func: Box::new(Expr::Identifier("range".to_string())),
                args: vec![first, second],
            }
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
            _ => BinaryOperator::Add,
        };
        if let Some(rhs) = inner.next() {
            res = Expr::BinaryOp(Box::new(res), op, Box::new(parse_expression(rhs)));
        }
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
            _ => BinaryOperator::Mul,
        };
        if let Some(rhs) = inner.next() {
            res = Expr::BinaryOp(Box::new(res), op, Box::new(parse_expression(rhs)));
        }
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
            _ => UnaryOperator::Not,
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
            _ => BinaryOperator::Pow,
        };
        if let Some(rhs) = inner.next() {
            res = Expr::BinaryOp(Box::new(res), op, Box::new(parse_expression(rhs)));
        }
    }
    res
}

fn parse_postfix_expr(pair: pest::iterators::Pair<Rule>) -> Expr {
    let mut inner = pair.into_inner();
    let first = inner.next().unwrap();
    let mut res = parse_expression(first);
    for op_pair in inner {
        let Some(op) = op_pair.into_inner().next() else {
            continue;
        };
        match op.as_rule() {
            Rule::function_call => {
                let mut args = Vec::new();
                if let Some(args_pair) = op.into_inner().next() {
                    for arg in args_pair.into_inner() {
                        args.push(parse_arg_item(arg));
                    }
                }
                res = Expr::FunctionCall {
                    func: Box::new(res),
                    args,
                };
            }
            Rule::cell_indexing => {
                let mut args = Vec::new();
                if let Some(args_pair) = op.into_inner().next() {
                    for arg in args_pair.into_inner() {
                        args.push(parse_arg_item(arg));
                    }
                }
                res = Expr::CellIndexing {
                    target: Box::new(res),
                    args,
                };
            }
            Rule::transpose => {
                if op.as_str().trim() == ".'" {
                    res = Expr::ArrayTranspose(Box::new(res));
                } else {
                    res = Expr::Transpose(Box::new(res));
                }
            }
            Rule::attr_access => {
                if let Some(property) = op
                    .into_inner()
                    .filter(|p| p.as_rule() == Rule::identifier)
                    .map(|p| p.as_str().trim().to_string())
                    .next()
                {
                    res = Expr::PropertyAccess {
                        target: Box::new(res),
                        property,
                    };
                }
            }
            _ => {}
        }
    }
    res
}

fn unquote_matlab_string(s: &str) -> String {
    if s.len() < 2 {
        return s.to_string();
    }
    let quote = s.chars().next().unwrap_or('\'');
    let content = &s[1..s.len() - 1];
    if quote == '\'' {
        content.replace("''", "'")
    } else {
        content.replace("\\\"", "\"")
    }
}

fn parse_number_literal(raw: &str) -> Expr {
    let s = raw.trim();
    if let Some(hex) = s.strip_prefix("0x").or_else(|| s.strip_prefix("0X")) {
        let cleaned = hex.replace('_', "");
        let val = u64::from_str_radix(&cleaned, 16)
            .map(|v| v as f64)
            .unwrap_or_else(|_| {
                u128::from_str_radix(&cleaned, 16)
                    .map(|v| v as f64)
                    .unwrap_or(f64::NAN)
            });
        Expr::Number(val)
    } else if let Some(bin) = s.strip_prefix("0b").or_else(|| s.strip_prefix("0B")) {
        let cleaned = bin.replace('_', "");
        let val = u64::from_str_radix(&cleaned, 2)
            .map(|v| v as f64)
            .unwrap_or_else(|_| {
                u128::from_str_radix(&cleaned, 2)
                    .map(|v| v as f64)
                    .unwrap_or(f64::NAN)
            });
        Expr::Number(val)
    } else if s.ends_with('i') || s.ends_with('j') {
        let num_part = &s[..s.len() - 1];
        let val = if num_part.is_empty() {
            1.0
        } else {
            num_part.parse::<f64>().unwrap_or(1.0)
        };
        Expr::Complex(0.0, val)
    } else {
        Expr::Number(s.parse::<f64>().unwrap_or(f64::NAN))
    }
}

fn parse_atom(pair: pest::iterators::Pair<Rule>) -> Expr {
    let mut inner = pair.into_inner();
    let Some(first) = inner.next() else {
        return Expr::Number(f64::NAN);
    };
    match first.as_rule() {
        Rule::number => parse_number_literal(first.as_str()),
        Rule::string => Expr::String(unquote_matlab_string(first.as_str())),
        Rule::identifier => Expr::Identifier(first.as_str().trim().to_string()),
        Rule::matrix => {
            let mut matrix = Vec::new();
            for row_pair in first.into_inner() {
                if row_pair.as_rule() == Rule::row {
                    let row_items = parse_row_items(row_pair);
                    if !row_items.is_empty() {
                        matrix.push(row_items);
                    }
                }
            }
            Expr::Matrix(matrix)
        }
        Rule::cell_array => {
            let mut cell_array = Vec::new();
            for row_pair in first.into_inner() {
                if row_pair.as_rule() == Rule::row {
                    let row_items = parse_row_items(row_pair);
                    if !row_items.is_empty() {
                        cell_array.push(row_items);
                    }
                }
            }
            Expr::CellArray(cell_array)
        }
        Rule::function_handle => {
            let name = first
                .into_inner()
                .next()
                .map(|p| p.as_str().trim().to_string())
                .unwrap_or_default();
            Expr::FunctionHandle(name)
        }
        Rule::expression => parse_expression(first),
        Rule::end_kw => Expr::End,
        _ => Expr::Identifier(first.as_str().trim().to_string()),
    }
}

fn parse_arg_item(pair: pest::iterators::Pair<Rule>) -> Expr {
    let mut inner = pair.clone().into_inner();
    let Some(first) = inner.next() else {
        return Expr::Identifier(pair.as_str().trim().to_string());
    };
    match first.as_rule() {
        Rule::expression => parse_expression(first),
        Rule::colon_arg => Expr::Colon,
        Rule::keyword_arg => {
            let mut sub = first.into_inner();
            let key = sub
                .next()
                .map(|p| p.as_str().trim().to_string())
                .unwrap_or_default();
            let val = sub
                .next()
                .map(parse_expression)
                .unwrap_or(Expr::Number(f64::NAN));
            Expr::KeywordArg(key, Box::new(val))
        }
        _ => Expr::Identifier(pair.as_str().trim().to_string()),
    }
}
