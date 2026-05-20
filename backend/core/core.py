from lark import Lark, Transformer, v_args, Tree
import numpy as np
import re
import traceback
import sys
import os
import io
import pathlib
import importlib.util
from typing import Any, Dict, List, Optional, Union, Set

# EBNF Grammar for UniLab (MATLAB-compatible)
UniLab_GRAMMAR = r"""
    start: separator* (stmt_sep separator*)* [stmt_no_sep]
    separator: SEMI | COMMA | NEWLINE
    stmt_sep: statement separator
    stmt_no_sep: statement (COMMA | SEMI)?

    ?statement: assignment
              | if_stmt
              | for_stmt
              | while_stmt
              | switch_stmt
              | try_stmt
              | function_def
              | clear_stmt
              | global_stmt
              | return_stmt
              | break_stmt
              | continue_stmt
              | import_stmt
              | export_stmt
              | expr_stmt
              | command_call

    ?assignment: multi_assignment | single_assignment
    multi_assignment.10: lhs_list EQUAL expression
    single_assignment: postfix_expr EQUAL expression
    lhs_list: LBRACKET (IDENTIFIER (COMMA? IDENTIFIER)*)? RBRACKET
    
    if_stmt: IF expression block (ELSEIF expression block)* [ELSE block] END
    for_stmt: FOR IDENTIFIER EQUAL expression block END
    while_stmt: WHILE expression block END
    switch_stmt: SWITCH expression case_clause* [otherwise_clause] END
    case_clause: CASE expression block
    otherwise_clause: OTHERWISE block
    
    try_stmt: TRY block CATCH [IDENTIFIER] block END
    
    function_def: FUNCTION [function_ret] IDENTIFIER LPAR [func_params] RPAR block END
    function_ret: (IDENTIFIER | lhs_list) EQUAL
    func_params: IDENTIFIER (COMMA? IDENTIFIER)*
    
    block: separator* (stmt_sep separator*)* [stmt_no_sep]
    
    clear_stmt: CLEAR (IDENTIFIER | "all")*
    global_stmt: GLOBAL IDENTIFIER+
    return_stmt: RETURN
    break_stmt: BREAK
    continue_stmt: CONTINUE
    
    import_stmt: IMPORT qualified_name
    export_stmt: EXPORT IDENTIFIER
    
    expr_stmt: expression
    
    ?expression: anonymous_func | logical_or
    
    ?logical_or: logical_and (OR logical_and)*
    ?logical_and: comparison (AND comparison)*
    ?comparison: range_expr (COMP_OP range_expr)*
    
    ?range_expr: addition
               | addition COLON addition -> range2
               | addition COLON addition COLON addition -> range3

    ?addition.5: multiplication (ADD_OP multiplication)*
    ?multiplication.5: power (MUL_OP power)*
    ?power: unary (POW_OP unary)*
    ?unary: UNARY_OP unary | postfix_expr
    
    ?postfix_expr: atom
                 | function_call
                 | cell_indexing
                 | postfix_expr QUOTE -> transpose
                 | postfix_expr DOT IDENTIFIER -> attr_access

    function_call.10: postfix_expr LPAR call_args? RPAR
    cell_indexing.10: postfix_expr LBRACE call_args? RBRACE

    ?atom: NUMBER                    -> number
         | STRING                    -> string
         | function_handle
         | END                       -> end_expr
         | IDENTIFIER                -> var
         | LPAR expression RPAR      -> atom_group
         | matrix
         | cell_array
    
    anonymous_func: AT LPAR func_params? RPAR expression
    function_handle: AT qualified_name
    
    ?qualified_name: IDENTIFIER (DOT IDENTIFIER)*
    
    call_args: arg_item (COMMA arg_item)*
    ?arg_item: expression | COLON -> colon_arg
    
    matrix: LBRACKET (row | SEMI | NEWLINE)* RBRACKET
    row: expression (COMMA? expression)*
    
    cell_array: LBRACE (row | SEMI | NEWLINE)* RBRACE
    
    command_call: IDENTIFIER (IDENTIFIER | STRING | NUMBER)+ -> cmd_call

    IDENTIFIER: /(?!function|end|if|elseif|else|for|while|switch|case|otherwise|try|catch|global|clear|return|break|continue|import|export)[a-zA-Z_][a-zA-Z0-9_]*/
    NUMBER: /(?:0x[0-9a-fA-F]+)|(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?[ij]?/
    STRING: /'(?:[^'\n]|'')*'/
    
    ADD_OP: "+" | "-" | ".+" | ".-"
    MUL_OP: "*" | "/" | "\\" | ".*" | "./" | ".\\"
    POW_OP: "^" | ".^"
    UNARY_OP: "+" | "-" | "~"
    COMP_OP: "==" | "~=" | ">=" | "<=" | ">" | "<"
    AND: "&" | "&&"
    OR: "|" | "||"
    
    EQUAL: "="
    LPAR: "("
    RPAR: ")"
    LBRACKET: "["
    RBRACKET: "]"
    LBRACE: "{"
    RBRACE: "}"
    DOT: "."
    COMMA: ","
    SEMI: ";"
    COLON: ":"
    AT: "@"
    QUOTE: "'"
    
    IF: "if"
    ELSEIF: "elseif"
    ELSE: "else"
    FOR: "for"
    WHILE: "while"
    SWITCH: "switch"
    CASE: "case"
    OTHERWISE: "otherwise"
    TRY: "try"
    CATCH: "catch"
    FUNCTION: "function"
    CLEAR: "clear"
    GLOBAL: "global"
    RETURN: "return"
    BREAK: "break"
    CONTINUE: "continue"
    IMPORT: "import"
    EXPORT: "export"
    END: "end"
    
    NEWLINE: (/\r?\n/ WS_INLINE*)+
    %import common.WS_INLINE
    %ignore WS_INLINE
    CONTINUATION: "..." /.*/ NEWLINE
    %ignore CONTINUATION
    COMMENT: /%[^\n]*/
    %ignore COMMENT
"""

class UniLabToPython(Transformer):
    def __init__(self):
        self.variables = set()
        self.globals = set()
        self.called_functions = set()
        self.added_paths = set()
        self._switch_depth = 0

    def _indent(self, lines):
        if not lines: return ["    pass"]
        flat_lines = []
        if isinstance(lines, str):
            flat_lines = lines.split('\n')
        else:
            for item in lines:
                if isinstance(item, list): flat_lines.extend(item)
                else: flat_lines.extend(str(item).split('\n'))
        
        res = ["    " + l if l.strip() else l for l in flat_lines]
        if not res: return ["    pass"]
        return res

    def number(self, n):
        s = str(n[0])
        if s.endswith('i'): return s[:-1] + 'j'
        return s
    def string(self, s):
        content = str(s[0])[1:-1].replace("''", "'")
        return repr(content)
    def end_expr(self, items): return "unilab_end"
    def colon_arg(self, items): return "slice(None)"

    def range2(self, items):
        return f"unilab_range({items[0]}, {items[2]})"

    def range3(self, items):
        return f"unilab_range({items[0]}, {items[4]}, {items[2]})"

    def _escape_name(self, name):
        keywords = {
            'False', 'None', 'True', 'and', 'as', 'assert', 'async', 'await', 
            'break', 'class', 'continue', 'def', 'del', 'elif', 'else', 
            'except', 'finally', 'for', 'from', 'global', 'if', 'import', 
            'in', 'is', 'lambda', 'nonlocal', 'not', 'or', 'pass', 'raise', 
            'return', 'try', 'while', 'with', 'yield'
        }
        if name in keywords: return f"{name}_"
        return name

    def var(self, items):
        name = str(items[0])
        name = self._escape_name(name)
        if name == "nargin": return "nargin"
        self.variables.add(name)
        self.called_functions.add(name)
        return f"unilab_call({name})"

    def qualified_name(self, items):
        return ".".join(str(i) for i in items if str(i) != '.')

    def attr_access(self, items):
        target, attr = items[0], items[2]
        if isinstance(target, str) and target.startswith('unilab_call(') and target.endswith(')') and ',' not in target:
             target = target[12:-1]
        return f"unilab_get({target}, '{attr}')"

    def function_call(self, items):
        name = items[0]
        # items[1] is LPAR, items[2] is call_args?
        args = items[2] if len(items) > 3 else None
        
        if isinstance(name, str) and name.startswith('unilab_call(') and name.endswith(')') and ',' not in name:
             name = name[12:-1]
        self.called_functions.add(str(name))
        
        if name == "pi" and not args: return "np.pi"
        if name == "addpath" and args:
            arg_list = args if isinstance(args, list) else [args]
            for a in arg_list:
                if str(a).startswith("'") and str(a).endswith("'"):
                    self.added_paths.add(str(a)[1:-1])

        arg_str = ", ".join(map(str, args)) if isinstance(args, list) else (str(args) if args is not None else "")
        if arg_str:
            return f"unilab_call({name}, {arg_str})"
        return f"unilab_call({name})"

    def cell_indexing(self, items):
        target = items[0]
        if isinstance(target, str) and target.startswith('unilab_call(') and target.endswith(')') and ',' not in target:
             target = target[12:-1]
        args = items[2] if len(items) > 3 else None
        arg_str = ", ".join(map(str, args)) if isinstance(args, list) else (str(args) if args is not None else "")
        if arg_str:
            return f"unilab_call({target}, {arg_str})"
        return f"unilab_call({target})"

    def transpose(self, items):
        target = items[0]
        if isinstance(target, str) and target.startswith('unilab_call(') and target.endswith(')') and ',' not in target:
             target = target[12:-1]
        return f"{target}.T"

    def unary(self, items):
        if len(items) == 2:
            op, val = str(items[0]), items[1]
            if op == "~": return f"unilab_not({val})"
            return f"{op}{val}"
        return items[0]

    def power(self, items):
        if len(items) == 1: return items[0]
        res = items[0]
        for i in range(1, len(items), 2):
            op = str(items[i])
            if op == ".^":
                res = f"unilab_dot_pow({res}, {items[i+1]})"
            else:
                res = f"unilab_pow({res}, {items[i+1]})"
        return res

    def multiplication(self, items):
        if len(items) == 1: return items[0]
        res = items[0]
        for i in range(1, len(items), 2):
            op, right = str(items[i]), items[i+1]
            if op == ".*": res = f"unilab_dot_mul({res}, {right})"
            elif op == "./": res = f"unilab_dot_div({res}, {right})"
            elif op == ".\\": res = f"unilab_dot_ldiv({res}, {right})"
            elif op == "*": res = f"unilab_mul({res}, {right})"
            elif op == "/": res = f"unilab_div({res}, {right})"
            elif op == "\\": res = f"unilab_ldiv({res}, {right})"
            else: res = f"({res} {op} {right})" 
        return res

    def addition(self, items):
        if len(items) == 1: return items[0]
        res = f"({items[0]}"
        for i in range(1, len(items), 2):
            res += f" {items[i]} {items[i+1]}"
        res += ")"
        return res

    def comparison(self, items):
        if len(items) == 1: return items[0]
        res = items[0]
        for i in range(1, len(items), 2):
            op, right = str(items[i]), items[i+1]
            if op == "==": res = f"unilab_eq({res}, {right})"
            elif op == "~=": res = f"unilab_ne({res}, {right})"
            elif op == ">": res = f"unilab_gt({res}, {right})"
            elif op == "<": res = f"unilab_lt({res}, {right})"
            elif op == ">=": res = f"unilab_ge({res}, {right})"
            elif op == "<=": res = f"unilab_le({res}, {right})"
        return res

    def logical_and(self, items):
        if len(items) == 1: return items[0]
        res = items[0]
        for i in range(1, len(items), 2):
            res = f"unilab_and({res}, {items[i+1]})"
        return res

    def logical_or(self, items):
        if len(items) == 1: return items[0]
        res = items[0]
        for i in range(1, len(items), 2):
            res = f"unilab_or({res}, {items[i+1]})"
        return res

    def multi_assignment(self, items):
        lhs, expr = items[0], items[2]
        # items[0] is from lhs_list, which returns a list of strings
        stmt = f"({', '.join(lhs)}) = {expr}"
        return {"type": "assignment", "stmt": stmt, "lhs": f"[{', '.join(lhs)}]", "is_multi": True, "names": lhs}

    def single_assignment(self, items):
        lhs, expr = items[0], items[2]
        
        # Hack to fix mis-parsed multi-assignments where Lark preferred 'matrix' atom
        if isinstance(lhs, str) and lhs.startswith('unilab_matrix_concat('):
             # Try to extract identifiers from unilab_call(name) patterns
             matches = re.findall(r"unilab_call\(([^,)]+)\)", lhs)
             if matches and 'unilab_matrix_concat' not in str(matches):
                  # Check if there are any non-identifiers
                  is_pure_ids = all(re.match(r"^[a-zA-Z_][a-zA-Z0-9_]*$", m) for m in matches)
                  if is_pure_ids:
                      stmt = f"({', '.join(matches)}) = {expr}"
                      for n in matches: self.variables.add(n)
                      return {"type": "assignment", "stmt": stmt, "lhs": f"[{', '.join(matches)}]", "is_multi": True, "names": matches}

        # items[0] is from postfix_expr, which returns a string
        if isinstance(lhs, str) and lhs.startswith('unilab_call(') and lhs.endswith(')') and ',' not in lhs:
             lhs = lhs[12:-1]

        if "unilab_call" in str(lhs) or "unilab_get" in str(lhs):
            if "unilab_call" in str(lhs):
                match = re.match(r"unilab_call\(([^,]+)(?:,\s*(.*))?\)", str(lhs))
                if match:
                    obj, args = match.group(1), match.group(2)
                    stmt = f"unilab_set({obj}, {expr}{', ' + args if args else ''})"
                    return {"type": "assignment", "stmt": stmt, "lhs": obj, "is_multi": False}
            
            if "unilab_get" in str(lhs):
                match = re.match(r"unilab_get\(([^,]+),\s*([^)]+)\)", str(lhs))
                if match:
                    obj, attr = match.group(1), match.group(2)
                    stmt = f"unilab_set({obj}, {expr}, {attr})"
                    return {"type": "assignment", "stmt": stmt, "lhs": obj, "is_multi": False}

        self.variables.add(str(lhs))
        return {"type": "assignment", "stmt": f"{lhs} = {expr}", "lhs": str(lhs), "is_multi": False}

    def expr_stmt(self, items):
        return {"type": "expr", "expr": items[0]}

    def stmt_sep(self, items):
        return self._process_stmt(items[0], str(items[1]) == ";")

    def stmt_no_sep(self, items):
        has_semi = len(items) > 1 and str(items[1]) == ";"
        return self._process_stmt(items[0], has_semi)

    def _process_stmt(self, stmt, has_semi):
        if isinstance(stmt, dict):
            if stmt.get("type") == "assignment":
                python_stmt = stmt["stmt"]
                if not has_semi:
                    lhs_esc = stmt["lhs"].replace("\\", "\\\\").replace("'", "\\'")
                    if stmt.get("is_multi"):
                        return f"{python_stmt}; unilab_print_var('{lhs_esc}', ({', '.join(stmt['names'])}))"
                    else:
                        return f"{python_stmt}; unilab_print_var('{lhs_esc}', {stmt['lhs']})"
                return python_stmt
            if stmt.get("type") == "expr":
                expr = stmt["expr"]
                if not has_semi:
                    expr_esc = str(expr).replace("\\", "\\\\").replace("'", "\\'")
                    return f"ans = unilab_print_and_save_ans('{expr_esc}', {expr})"
                return str(expr)
        if isinstance(stmt, list):
            return "\n".join(stmt)
        return str(stmt)

    def separator(self, items):
        s = str(items[0])
        if s == ",": return ""
        return s

    def lhs_list(self, items):
        names = [str(i) for i in items if str(i) not in ["[", "]", ","]]
        for n in names: self.variables.add(n)
        return names

    def function_ret(self, items):
        return items[0]

    def block(self, items):
        res = []
        for i in items:
            if i is None: continue
            if isinstance(i, list):
                for sub in i:
                    if sub: res.append(str(sub))
            else:
                s = str(i)
                if s: res.append(s)
        return res

    def start(self, items):
        return "\n".join(self.block(items))

    def if_stmt(self, items):
        cond = items[1]
        block = items[2]
        lines = [f"if unilab_to_bool({cond}):"]
        lines.extend(self._indent(block))
        i = 3
        while i < len(items):
            item = items[i]
            if str(item) == "elseif":
                e_cond, e_block = items[i+1], items[i+2]
                lines.append(f"elif unilab_to_bool({e_cond}):")
                lines.extend(self._indent(e_block))
                i += 3
            elif str(item) == "else":
                lines.append("else:")
                lines.extend(self._indent(items[i+1]))
                i += 2
            else: i += 1
        return lines

    def for_stmt(self, items):
        var, expr, block = str(items[1]), items[3], items[4]
        self.variables.add(var)
        lines = [f"for {var} in unilab_iter({expr}):"]
        lines.extend(self._indent(block))
        return lines

    def while_stmt(self, items):
        cond, block = items[1], items[2]
        lines = [f"while unilab_to_bool({cond}):"]
        lines.extend(self._indent(block))
        return lines

    def switch_stmt(self, items):
        expr = items[1]
        self._switch_depth += 1
        var_name = f"_sw_{self._switch_depth}"
        lines = [f"{var_name} = {expr}"]
        clauses = items[2:-1]
        first = True
        for clause in clauses:
            if isinstance(clause, list):
                if first:
                    clause[0] = clause[0].replace("elif", "if").replace("_sw_tmp", var_name)
                    first = False
                else:
                    clause[0] = clause[0].replace("_sw_tmp", var_name)
                lines.extend(clause)
        if first: lines.append("    pass")
        self._switch_depth -= 1
        return lines

    def case_clause(self, items):
        expr, block = items[1], items[2]
        return [f"elif _sw_tmp == {expr}:"] + self._indent(block)

    def otherwise_clause(self, items):
        return ["else:"] + self._indent(items[1])

    def try_stmt(self, items):
        lines = ["try:"]
        block = items[1]
        lines.extend(self._indent(block))
        idx = 2
        if idx < len(items) and str(items[idx]) == "catch":
            idx += 1
            err_var = items[idx] if not isinstance(items[idx], list) and str(items[idx]) != "END" else None
            if err_var: idx += 1
            catch_block = items[idx]
            lines.append(f"except Exception as {err_var if err_var else 'e'}:")
            lines.extend(self._indent(catch_block))
        return lines

    def function_def(self, items):
        ret = items[1]
        name = str(items[2])
        params = items[4]
        if params is None: params = []
        if isinstance(params, str): params = []
        block = items[-2]
        raw_params = [str(p) for p in params if str(p) not in [",", "(", ")"]]
        param_list_with_defaults = [f"{p}=None" for p in raw_params]
        lines = [f"def {name}({', '.join(param_list_with_defaults)}):"]
        inner = [f"nargin = unilab_nargin_sum(1 for x in [{', '.join(raw_params)}] if x is not None)"]
        inner.extend(block)
        if ret:
            if isinstance(ret, list): inner.append(f"return ({', '.join(ret)})")
            elif isinstance(ret, dict) and ret.get("type") == "assignment":
                # Handle 'y = ' from function_ret
                ret_name = ret["lhs"]
                inner.append(f"return {ret_name}")
            else:
                # If function_ret returned something else
                inner.append(f"return {ret}")
        lines.extend(self._indent(inner))
        return lines

    def return_stmt(self, items): return "return"
    def break_stmt(self, items): return "break"
    def continue_stmt(self, items): return "continue"

    def func_params(self, items): return [str(i) for i in items if str(i) != ","]
    def call_args(self, items): return [str(i) for i in items if str(i) != ","]
    
    def matrix(self, items):
        rows = []
        current_row = []
        for item in items:
            if isinstance(item, list): current_row.extend(item)
            elif item is not None and str(item).strip() in [";", "\n", ""]:
                if str(item).strip() == ";" or "\n" in str(item):
                    if current_row: rows.append(current_row); current_row = []
        if current_row: rows.append(current_row)
        row_strs = [f"[{', '.join(map(str, r))}]" for r in rows]
        return f"unilab_matrix_concat({', '.join(row_strs)})"

    def cell_array(self, items):
        rows = []
        current_row = []
        for item in items:
            if isinstance(item, list): current_row.extend(item)
            elif item is not None and str(item).strip() in [";", "\n", ""]:
                if str(item).strip() == ";" or "\n" in str(item):
                    if current_row: rows.append(current_row); current_row = []
        if current_row: rows.append(current_row)
        if not rows: return "unilab_cell_concat()"
        row_strs = [f"[{', '.join(map(str, r))}]" for r in rows]
        return f"unilab_cell_concat({', '.join(row_strs)})"
        
    def row(self, items): return [str(i) for i in items if str(i) != ","]
    
    def anonymous_func(self, items):
        params = items[2] if len(items) > 3 else []
        expr = items[-1]
        param_list = [str(p) for p in params if str(p) not in [",", "(", ")"]]
        return f"unilab_handle(lambda {', '.join(param_list)}: ({expr}))"
        
    def function_handle(self, items):
        return f"unilab_handle({str(items[1])})"
        
    def cmd_call(self, items):
        name, args = str(items[0]), [f"'{str(a)}'" for a in items[1:]]
        return f"{name}({', '.join(args)})"
        
    def clear_stmt(self, items):
        names = [str(i) for i in items if str(i) not in ["clear", " "]]
        if not names or "all" in names: return "unilab_clear_workspace(globals())"
        quoted = [f"'{n}'" for n in names]
        return f"unilab_clear_variables(globals(), [{', '.join(quoted)}])"
        
    def global_stmt(self, items):
        names = [str(i) for i in items if str(i) != "global"]
        for n in names: self.globals.add(n)
        return f"global {', '.join(names)}"
        
    def import_stmt(self, items): return f"import {items[1]}"
    def export_stmt(self, items): return f"# export {items[1]}"
    def atom_group(self, items): return items[1]

class UniLabTranspiler:
    def __init__(self):
        self.parser = Lark(UniLab_GRAMMAR, parser='earley', ambiguity='resolve')
        self.transformer = UniLabToPython()
    def transpile(self, code: str):
        try:
            tree = self.parser.parse(code + "\n")
            self.transformer.variables, self.transformer.called_functions, self.transformer.added_paths = set(), set(), set()
            result = self.transformer.transform(tree)
            return str(result), self.transformer.called_functions, self.transformer.added_paths
        except Exception as e: raise Exception(f"Transpilation Error: {str(e)}")