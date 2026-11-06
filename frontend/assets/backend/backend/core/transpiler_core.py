from lark import Lark, Transformer
import re
import uuid

# Internal single-character transpose markers emitted by _disambiguate_transposes
_CONJ_TRANSPOSE_CHAR = "\x1e"
_DOT_TRANSPOSE_CHAR = "\x1f"

_STATEMENT_KEYWORDS = {
    "function", "if", "elseif", "else", "for", "parfor", "while",
    "switch", "case", "otherwise", "try", "catch",
    "global", "clear", "return", "break", "continue",
    "import", "export", "edit",
}

_DOUBLE_STR_ESC_RE = re.compile(
    r'\\(x[0-9a-fA-F]{2}|u[0-9a-fA-F]{4}|U[0-9a-fA-F]{8}|[0-7]{1,3}|[\\"\'abfnrtv]|.)'
)

_SIMPLE_ESCAPES = {
    "\\": "\\",
    '"': '"',
    "'": "'",
    "a": "\a",
    "b": "\b",
    "f": "\f",
    "n": "\n",
    "r": "\r",
    "t": "\t",
    "v": "\v",
}


def _unescape_double_quoted(raw: str) -> str:
    """Unescape MATLAB/C-style escapes inside double quotes without corrupting UTF-8 or raw backslashes."""
    def _replace(match: re.Match) -> str:
        esc = match.group(1)
        if esc in _SIMPLE_ESCAPES:
            return _SIMPLE_ESCAPES[esc]
        if esc.startswith(("x", "u", "U")) and len(esc) in (3, 5, 9):
            return chr(int(esc[1:], 16))
        if esc[0] in "01234567" and all(c in "01234567" for c in esc):
            return chr(int(esc, 8))
        return "\\" + esc

    return _DOUBLE_STR_ESC_RE.sub(_replace, raw)


def _disambiguate_transposes(code: str) -> str:
    """
    Pre-scan UniLab/MATLAB code outside '%' comments, '...' continuations, and strings to
    distinguish single-quoted string literals ('...') from conjugate transpose (') and
    non-conjugate array transpose (.').
    Preserves line numbers and column offsets.
    """
    n = len(code)
    out = []
    i = 0
    just_transposed = False

    while i < n:
        ch = code[i]

        # Line continuation `...` ignores rest of line (including apostrophes in comments after `...`)
        if ch == "." and code[i:i + 3] == "...":
            nl = code.find("\n", i + 3)
            if nl == -1:
                out.append(code[i:])
                break
            out.append(code[i:nl + 1])
            i = nl + 1
            just_transposed = False
            continue

        # `%` comment outside strings
        if ch == "%":
            nl = code.find("\n", i + 1)
            if nl == -1:
                out.append(code[i:])
                break
            out.append(code[i:nl + 1])
            i = nl + 1
            just_transposed = False
            continue

        # Double-quoted string `"..."`
        if ch == '"':
            start = i
            i += 1
            while i < n:
                c2 = code[i]
                if c2 == "\\":
                    i += 2
                    continue
                if c2 == '"':
                    i += 1
                    break
                i += 1
            out.append(code[start:i])
            just_transposed = False
            continue

        # Non-conjugate array transpose `.'`
        if ch == "." and i + 1 < n and code[i + 1] == "'":
            out.append(_DOT_TRANSPOSE_CHAR + " ")
            i += 2
            just_transposed = True
            continue

        # Single quote `'`: either transpose or opening `'...'` string literal
        if ch == "'":
            is_transpose = False
            if just_transposed:
                is_transpose = True
            elif i > 0:
                prev = code[i - 1]
                if prev in ")]}":
                    is_transpose = True
                elif prev.isalnum() or prev == "_":
                    # Check preceding word is not a statement keyword (e.g., `case'a'`)
                    w_end = i
                    w_start = i - 1
                    while w_start > 0 and (code[w_start - 1].isalnum() or code[w_start - 1] == "_"):
                        w_start -= 1
                    prev_word = code[w_start:w_end]
                    if prev_word not in _STATEMENT_KEYWORDS:
                        is_transpose = True

            if is_transpose:
                out.append(_CONJ_TRANSPOSE_CHAR)
                i += 1
                just_transposed = True
                continue

            # Otherwise, scan a single-quoted string `'...'` (with `''` escaped quotes)
            start = i
            i += 1
            while i < n:
                c2 = code[i]
                if c2 == "\n":
                    # Unclosed string on this line; stop so Lark reports syntax error cleanly
                    break
                if c2 == "'":
                    if i + 1 < n and code[i + 1] == "'":
                        i += 2
                        continue
                    i += 1
                    break
                i += 1
            out.append(code[start:i])
            just_transposed = False
            continue

        out.append(ch)
        if not ch.isspace():
            just_transposed = False
        i += 1

    return "".join(out)


class ExprStr(str):
    """String subclass carrying structured postfix AST metadata for clean LHS assignment codegen."""
    def __new__(cls, value: str, ast_node=None):
        obj = super().__new__(cls, value)
        obj.ast_node = ast_node
        return obj


# EBNF Grammar for UniLab (MATLAB-compatible)
UniLab_GRAMMAR = r"""
    start: separator* (stmt_sep separator*)* [stmt_no_sep]
    separator: SEMI | COMMA | NEWLINE
    stmt_sep: statement separator
    stmt_no_sep: statement (COMMA | SEMI)?

    ?statement: assignment
              | if_stmt
              | for_stmt
              | parfor_stmt
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
    lhs_list: LBRACKET ( (IDENTIFIER | UNARY_OP) (COMMA? (IDENTIFIER | UNARY_OP))* )? RBRACKET
    
    if_stmt: IF expression separator+ block (ELSEIF expression separator+ block)* [ELSE separator* block] END
    for_stmt: FOR IDENTIFIER EQUAL expression separator+ block END
    parfor_stmt: PARFOR IDENTIFIER EQUAL expression separator+ block END
    while_stmt: WHILE expression separator+ block END
    switch_stmt: SWITCH expression separator* case_clause* [otherwise_clause] END
    case_clause: CASE expression separator* block
    otherwise_clause: OTHERWISE separator* block
    
    try_stmt: TRY block catch_clause END
    catch_clause: catch_with_var | catch_no_var
    catch_with_var.10: CATCH IDENTIFIER separator* block
    catch_no_var: CATCH separator* block
    
    function_def: FUNCTION [function_ret] IDENTIFIER LPAR [func_params] RPAR block END
    function_ret: (IDENTIFIER | lhs_list) EQUAL
    func_params: (IDENTIFIER | UNARY_OP) (COMMA? (IDENTIFIER | UNARY_OP))*
    
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
    ?multiplication.5: unary (MUL_OP unary)*
    ?unary: UNARY_OP unary | power
    ?power: postfix_expr (POW_OP signed_atom)*
    ?signed_atom: UNARY_OP signed_atom | postfix_expr
    
    ?postfix_expr: atom
                 | function_call
                 | cell_indexing
                 | postfix_expr CONJ_TRANSPOSE -> transpose
                 | postfix_expr DOT_TRANSPOSE -> array_transpose
                 | postfix_expr QUOTE -> transpose
                 | postfix_expr DOT IDENTIFIER -> attr_access

    function_call.200: postfix_expr LPAR call_args? RPAR
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
    function_handle: AT (qualified_name | FILE_PATH)
    
    ?qualified_name: IDENTIFIER (DOT IDENTIFIER)*
    
    call_args: arg_item (COMMA arg_item)*
    ?arg_item: keyword_arg | expression | COLON -> colon_arg
    keyword_arg: IDENTIFIER EQUAL expression
    
    matrix: LBRACKET (row | SEMI | NEWLINE)* RBRACKET
    row: expression (COMMA? expression)*
    
    cell_array: LBRACE (row | SEMI | NEWLINE)* RBRACE
    
    command_call: IDENTIFIER (IDENTIFIER | STRING | NUMBER)+ -> cmd_call

    IDENTIFIER: /(?!(?:function|end|if|elseif|else|for|parfor|while|switch|case|otherwise|try|catch|global|clear|return|break|continue|import|export|edit)\b)[a-zA-Z_][a-zA-Z0-9_]*/
    FILE_PATH: /[a-zA-Z0-9_\/]+\.m/
    NUMBER: /(?:0x[0-9a-fA-F]+)|(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?[ij]?/
    STRING: /'([^'\n]|'')*'|"([^"\\]|\\.)*"/
    
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
    CONJ_TRANSPOSE: "\x1e"
    DOT_TRANSPOSE: "\x1f"
    
    IF: "if"
    ELSEIF: "elseif"
    ELSE: "else"
    FOR: "for"
    PARFOR: "parfor"
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
        self.functions = []
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
        s_val = str(s[0])
        quote = s_val[0]
        if quote == "'":
            content = s_val[1:-1].replace("''", "'")
        else:
            content = _unescape_double_quoted(s_val[1:-1])
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

    def _unwrap_var_expr(self, target):
        node = getattr(target, "ast_node", None)
        if node is not None and node[0] == "var":
            return node[1]
        if isinstance(target, str) and target.startswith('unilab_call(') and target.endswith(')') and ',' not in target:
            return target[12:-1]
        return str(target)

    def var(self, items):
        name = str(items[0])
        name = self._escape_name(name)
        if name in ("nargin", "nargout", "varargin", "varargout", "ans", "pi", "inf", "Inf", "nan", "NaN", "eps", "i", "j", "realmax", "realmin", "true", "false", "error", "clc", "whos", "fprintf"): 
            return ExprStr(name, ("var", name))
        
        self.variables.add(name)
        self.called_functions.add(name)
        return ExprStr(f"unilab_call({name})", ("var", name))

    def qualified_name(self, items):
        return ".".join(str(i) for i in items if str(i) != '.')

    def attr_access(self, items):
        target, attr = items[0], str(items[2])
        target_node = getattr(target, "ast_node", None)
        if target_node is not None and target_node[0] == "var":
            name = target_node[1]
            if name not in self.variables:
                base_str = f"unilab_get_undefined('{name}', globals())"
            else:
                base_str = name
            return ExprStr(f"unilab_get({base_str}, '{attr}')", ("attr", target_node, attr))
        return ExprStr(f"unilab_get({target}, '{attr}')", ("attr", target_node or ("expr", str(target)), attr))

    def function_call(self, items):
        target = items[0]
        args = items[2] if len(items) > 3 else None
        target_node = getattr(target, "ast_node", None)
        name = self._unwrap_var_expr(target)
        if target_node is None or target_node[0] == "var":
            self.called_functions.add(str(name))
        
        if name == "pi" and not args:
            return ExprStr("np.pi", ("expr", "np.pi"))
        if name == "addpath" and args:
            arg_list_check = args if isinstance(args, list) else [args]
            for a in arg_list_check:
                if str(a).startswith("'") and str(a).endswith("'"):
                    self.added_paths.add(str(a)[1:-1])

        arg_list = args if isinstance(args, list) else ([args] if args is not None else [])
        arg_str = ", ".join(map(str, arg_list))
        code_str = f"unilab_call({name}, {arg_str})" if arg_str else f"unilab_call({name})"
        return ExprStr(code_str, ("call", target_node or ("expr", str(name)), [str(a) for a in arg_list]))

    def cell_indexing(self, items):
        target = items[0]
        target_node = getattr(target, "ast_node", None)
        base = self._unwrap_var_expr(target)
        args = items[2] if len(items) > 3 else None
        arg_list = args if isinstance(args, list) else ([args] if args is not None else [])
        arg_str = ", ".join(map(str, arg_list))
        code_str = f"unilab_cell_get({base}, {arg_str})" if arg_str else f"unilab_cell_get({base})"
        return ExprStr(code_str, ("cell", target_node or ("expr", str(base)), [str(a) for a in arg_list]))

    def transpose(self, items):
        target = self._unwrap_var_expr(items[0])
        return f"unilab_transpose({target})"

    def array_transpose(self, items):
        target = self._unwrap_var_expr(items[0])
        return f"unilab_array_transpose({target})"

    def signed_atom(self, items):
        return self.unary(items)

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
            op = str(items[i])
            if op == ".+":
                op = "+"
            elif op == ".-":
                op = "-"
            res += f" {op} {items[i+1]}"
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
        if isinstance(expr, str) and expr.startswith("unilab_call("):
            expr = expr.replace("unilab_call(", f"unilab_call_nargout({len(lhs)}, ", 1)
        stmt = f"({', '.join(lhs)}) = {expr}"
        return {"type": "assignment", "stmt": stmt, "lhs": f"[{', '.join(lhs)}]", "is_multi": True, "names": lhs}

    def single_assignment(self, items):
        lhs, expr = items[0], items[2]
        
        # Fallback if Lark preferred 'matrix' atom on [a b] = func()
        if isinstance(lhs, str) and lhs.startswith('unilab_matrix_concat('):
            matches = re.findall(r"unilab_call\(([^,)]+)\)", lhs)
            if matches and 'unilab_matrix_concat' not in str(matches):
                is_pure_ids = all(re.match(r"^[a-zA-Z_][a-zA-Z0-9_]*$", m) for m in matches)
                if is_pure_ids:
                    if isinstance(expr, str) and expr.startswith("unilab_call("):
                        expr = expr.replace("unilab_call(", f"unilab_call_nargout({len(matches)}, ", 1)
                    stmt = f"({', '.join(matches)}) = {expr}"
                    for n in matches: self.variables.add(n)
                    return {"type": "assignment", "stmt": stmt, "lhs": f"[{', '.join(matches)}]", "is_multi": True, "names": matches, "nargout": len(matches)}

        if isinstance(expr, str) and expr.startswith("unilab_call("):
            expr = expr.replace("unilab_call(", "unilab_call_nargout(1, ", 1)

        lhs_node = getattr(lhs, "ast_node", None)
        if lhs_node is not None:
            if lhs_node[0] == "var":
                var_name = lhs_node[1]
                self.variables.add(var_name)
                return {"type": "assignment", "stmt": f"{var_name} = {expr}", "lhs": var_name, "is_multi": False}

            # Unwind postfix chain: call / cell / attr -> root var
            steps = []
            cur = lhs_node
            while isinstance(cur, tuple) and cur[0] in ("call", "cell", "attr"):
                kind = cur[0]
                if kind == "attr":
                    steps.append(("attr", cur[2]))
                else:
                    steps.append((kind, cur[2]))
                cur = cur[1]

            if isinstance(cur, tuple) and cur[0] == "var" and steps:
                steps.reverse()
                obj = cur[1]
                self.variables.add(obj)
                obj_lookup = f"{obj} if '{obj}' in locals() else globals().get('{obj}', None)"

                if len(steps) == 1:
                    kind, payload = steps[0]
                    if kind == "call":
                        args_str = ", ".join(payload)
                        stmt = f"{obj} = unilab_set({obj_lookup}, {expr}{', ' + args_str if args_str else ''})"
                        return {"type": "assignment", "stmt": stmt, "lhs": obj, "is_multi": False}
                    if kind == "cell":
                        args_str = ", ".join(payload)
                        stmt = f"{obj} = unilab_cell_set({obj_lookup}, {expr}{', ' + args_str if args_str else ''})"
                        return {"type": "assignment", "stmt": stmt, "lhs": obj, "is_multi": False}
                    if kind == "attr":
                        stmt = f"{obj} = unilab_set_attr({obj_lookup}, '{payload}', {expr}, globals())"
                        return {"type": "assignment", "stmt": stmt, "lhs": obj, "is_multi": False}

                # Arbitrary nested struct/index/cell assignment (e.g. s.field(1) = 5, s.a.b = 1, folds(i).train = idx)
                step_exprs = []
                for kind, payload in steps:
                    if kind == "attr":
                        step_exprs.append(f"('attr', {payload!r})")
                    else:
                        step_exprs.append(f"({kind!r}, [{', '.join(payload)}])")
                stmt = f"{obj} = unilab_set_nested({obj_lookup}, [{', '.join(step_exprs)}], {expr})"
                return {"type": "assignment", "stmt": stmt, "lhs": obj, "is_multi": False}

        lhs_str = self._unwrap_var_expr(lhs)
        self.variables.add(lhs_str)
        return {"type": "assignment", "stmt": f"{lhs_str} = {expr}", "lhs": lhs_str, "is_multi": False}

    def expr_stmt(self, items):
        expr = items[0]
        if isinstance(expr, str) and expr.startswith("unilab_call("):
            expr = expr.replace("unilab_call(", "unilab_call_nargout(0, ", 1)
        return {"type": "expr", "expr": expr}

    def stmt_sep(self, items):
        return self._process_stmt(items[0], str(items[1]) == ";")

    def stmt_no_sep(self, items):
        has_semi = len(items) > 1 and str(items[1]) == ";"
        return self._process_stmt(items[0], has_semi)

    def _process_stmt(self, stmt, has_semi):
        if isinstance(stmt, dict):
            if stmt.get("type") == "function_def":
                return stmt
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
        names = []
        _ignored_counter = 0
        for i in items:
            s = str(i)
            if s in ("[", "]", ","): continue
            if s == "~":
                _ignored_counter += 1
                ignored_name = f"_ignored_{uuid.uuid4().hex[:4]}_{_ignored_counter}"
                names.append(ignored_name)
            else:
                names.append(self._escape_name(s))
        for n in names: self.variables.add(n)
        return names

    def function_ret(self, items):
        ret = items[0]
        if isinstance(ret, list):
            return ret
        return self._escape_name(str(ret))

    def block(self, items):
        res = []
        for i in items:
            if i is None: continue
            if isinstance(i, dict) and i.get("type") == "function_def":
                # Nested function inside another block/function stays inline to preserve closure scope
                res.append(i["code"])
            elif isinstance(i, list):
                for sub in i:
                    if isinstance(sub, dict) and sub.get("type") == "function_def":
                        res.append(sub["code"])
                    elif sub:
                        res.append(str(sub))
            else:
                s = str(i)
                if s: res.append(s)
        return res

    def start(self, items):
        body_lines = []
        for i in items:
            if i is None:
                continue
            if isinstance(i, dict) and i.get("type") == "function_def":
                # Top-level function definitions are hoisted so script calls above them succeed
                self.functions.append(i["code"])
            elif isinstance(i, list):
                for sub in i:
                    if isinstance(sub, dict) and sub.get("type") == "function_def":
                        self.functions.append(sub["code"])
                    elif sub:
                        body_lines.append(str(sub))
            else:
                s = str(i)
                if s:
                    body_lines.append(s)
        return "\n".join(body_lines)

    def if_stmt(self, items):
        items = [i for i in items if not (isinstance(i, str) and i.strip() in ("", ";", ","))]
        cond, block = items[1], items[2]
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
        var = self._escape_name(str(items[1]))
        expr = items[3]
        block = next(i for i in items[4:] if isinstance(i, list))
        self.variables.add(var)
        lines = [f"for {var} in unilab_iter({expr}):"]
        lines.extend(self._indent(block))
        return lines

    def parfor_stmt(self, items):
        return self.for_stmt(items)

    def while_stmt(self, items):
        cond = items[1]
        block = next(i for i in items[2:] if isinstance(i, list))
        lines = [f"while unilab_to_bool({cond}):"]
        lines.extend(self._indent(block))
        return lines

    def switch_stmt(self, items):
        items = [i for i in items if not (isinstance(i, str) and i.strip() in ("", ";", ","))]
        expr = items[1]
        self._switch_depth += 1
        var_name = f"_sw_{self._switch_depth}"
        lines = [f"{var_name} = {expr}"]
        clauses = items[2:-1]
        first = True
        for clause in clauses:
            if isinstance(clause, list):
                if first:
                    if clause[0].startswith("elif "):
                        clause[0] = "if " + clause[0][5:].replace("_sw_tmp", var_name)
                    else:
                        clause[0] = clause[0].replace("_sw_tmp", var_name)
                    first = False
                else:
                    clause[0] = clause[0].replace("_sw_tmp", var_name)
                lines.extend(clause)
        if first: lines.append("pass")
        self._switch_depth -= 1
        return lines

    def case_clause(self, items):
        items = [i for i in items if not (isinstance(i, str) and i.strip() in ("", ";", ","))]
        expr, block = items[1], items[2]
        return [f"elif unilab_switch_match(_sw_tmp, {expr}):"] + self._indent(block)

    def otherwise_clause(self, items):
        items = [i for i in items if not (isinstance(i, str) and i.strip() in ("", ";", ","))]
        block = next((i for i in items[1:] if isinstance(i, list)), [])
        return ["else:"] + self._indent(block)

    def catch_with_var(self, items):
        err_var = items[1]
        block = next(i for i in reversed(items) if isinstance(i, list))
        err_name = self._escape_name(str(err_var))
        self.variables.add(err_name)
        lines = [
            f"except Exception as {err_name}:",
            f"    {err_name} = unilab_exception({err_name})"
        ]
        lines.extend(self._indent(block))
        return lines

    def catch_no_var(self, items):
        block = next((i for i in reversed(items) if isinstance(i, list)), [])
        lines = ["except Exception:"]
        lines.extend(self._indent(block))
        return lines

    def catch_clause(self, items):
        return items[0]

    def try_stmt(self, items):
        try_block = items[1]
        catch_lines = items[2]
        lines = ["try:"]
        lines.extend(self._indent(try_block))
        lines.extend(catch_lines)
        return lines

    def function_def(self, items):
        ret = items[1]
        name = self._escape_name(str(items[2]))
        params = items[4]
        if params is None: params = []
        if isinstance(params, str): params = []
        block = items[-2]
        raw_params = [self._escape_name(str(p)) for p in params if str(p) not in (",", "(", ")")]
        
        # Handle tilde (~) in parameters by converting to dummy names
        processed_params = []
        _ignored_counter = 0
        for p in raw_params:
            if p == "~":
                _ignored_counter += 1
                processed_params.append(f"_ignored_param_{uuid.uuid4().hex[:4]}_{_ignored_counter}")
            else:
                processed_params.append(p)
        raw_params = processed_params

        has_varargin = "varargin" in raw_params
        if has_varargin:
            idx = raw_params.index("varargin")
            py_params = [f"{p}=None" for p in raw_params[:idx]]
            py_params.append("*varargin_args")
        else:
            py_params = [f"{p}=None" for p in raw_params]

        lines = [f"def {name}({', '.join(py_params)}):"]
        
        inner = [
            f"nargin = unilab_nargin_sum(1 for x in [{', '.join(raw_params if not has_varargin else raw_params[:idx])}] if x is not None)" if not has_varargin else f"nargin = unilab_nargin_sum(1 for x in [{', '.join(raw_params[:idx])}] if x is not None) + len(varargin_args)",
            "nargout = unilab_get_nargout()"
        ]
        
        # Initialize output variables
        if ret:
            if isinstance(ret, list):
                for r in ret:
                    if r == "varargout":
                        inner.append("varargout = []")
                    elif r not in raw_params:
                        inner.append(f"{r} = None")
            else:
                if ret == "varargout":
                    inner.append("varargout = []")
                elif ret not in raw_params:
                    inner.append(f"{ret} = None")

        if has_varargin:
            inner.append("varargin = unilab_cell_concat([list(varargin_args)])")

        inner.extend(block)
        
        has_varargout = False
        if isinstance(ret, list) and "varargout" in ret:
            has_varargout = True
        elif isinstance(ret, str) and ret == "varargout":
            has_varargout = True

        # Determine the return statement for this function
        ret_stmt = "return None"
        if ret:
            if has_varargout:
                if isinstance(ret, list):
                    ret_stmt = f"return unilab_process_varargout(({', '.join(ret)}))"
                else:
                    ret_stmt = "return unilab_process_varargout(varargout)"
            elif isinstance(ret, list): ret_stmt = f"return ({', '.join(ret)})"
            elif isinstance(ret, dict) and ret.get("type") == "assignment":
                ret_stmt = f"return {ret['lhs']}"
            else:
                ret_stmt = f"return {ret}"
        
        # Replace early return markers in the block while preserving indentation
        def replace_return_marker(items_list, r_stmt):
            res = []
            for item in items_list:
                if isinstance(item, list):
                    res.append(replace_return_marker(item, r_stmt))
                elif isinstance(item, str):
                    if "__UNILAB_RETURN__" in item:
                        res.append(item.replace("__UNILAB_RETURN__", r_stmt))
                    else:
                        res.append(item)
                else:
                    res.append(item)
            return res
            
        inner = replace_return_marker(inner, ret_stmt)
        if ret:
            inner.append(ret_stmt)
            
        lines.extend(self._indent(inner))
        return {"type": "function_def", "name": name, "code": "\n".join(lines)}

    def return_stmt(self, items): return "__UNILAB_RETURN__"
    def break_stmt(self, items): return "break"
    def continue_stmt(self, items): return "continue"

    def func_params(self, items): return [self._escape_name(str(i)) for i in items if str(i) != ","]
    def call_args(self, items): return [str(i) for i in items if str(i) != ","]
    def keyword_arg(self, items): return f"{self._escape_name(str(items[0]))}={str(items[2])}"
    
    def matrix(self, items):
        rows = []
        current_row = []
        for item in items:
            if isinstance(item, list): current_row.extend(item)
            elif item is not None and str(item).strip() in (";", "\n", ""):
                if str(item).strip() == ";" or "\n" in str(item):
                    if current_row: rows.append(current_row); current_row = []
        if current_row: rows.append(current_row)
        row_strs = []
        for r in rows:
            items_str = [str(item) for item in r]
            row_strs.append(f"[{', '.join(items_str)}]")
        return f"unilab_matrix_concat({', '.join(row_strs)})"

    def cell_array(self, items):
        rows = []
        current_row = []
        for item in items:
            if isinstance(item, list): current_row.extend(item)
            elif item is not None and str(item).strip() in (";", "\n", ""):
                if str(item).strip() == ";" or "\n" in str(item):
                    if current_row: rows.append(current_row); current_row = []
        if current_row: rows.append(current_row)
        if not rows: return "unilab_cell_concat()"
        
        row_strs = []
        for r in rows:
            items_str = [str(item) for item in r]
            row_strs.append(f"[{', '.join(items_str)}]")
        return f"unilab_cell_concat({', '.join(row_strs)})"
        
    def row(self, items): return [str(i) for i in items if str(i) != ","]
    
    def anonymous_func(self, items):
        params = items[2] if len(items) > 3 else []
        expr = items[-1]
        raw_params = [self._escape_name(str(p)) for p in params if str(p) not in (",", "(", ")")]
        
        processed_params = []
        _ignored_counter = 0
        for p in raw_params:
            if p == "~":
                _ignored_counter += 1
                processed_params.append(f"_ignored_anon_{uuid.uuid4().hex[:4]}_{_ignored_counter}")
            else:
                processed_params.append(p)
        
        return f"unilab_handle(lambda {', '.join(processed_params)}: ({expr}))"
        
    def function_handle(self, items):
        target = str(items[1])
        if '.' in target or '/' in target:
            return f"unilab_handle('{target}')"
        return f"unilab_handle({self._escape_name(target)})"
        
    def cmd_call(self, items):
        name = self._escape_name(str(items[0]))
        args = []
        for a in items[1:]:
            sa = str(a)
            if (sa.startswith("'") and sa.endswith("'")) or (sa.startswith('"') and sa.endswith('"')):
                args.append(self.string([sa]))
            else:
                args.append(repr(sa))
        self.called_functions.add(name)
        return f"{name}({', '.join(args)})"
        
    def clear_stmt(self, items):
        raw_names = [str(i) for i in items if str(i) not in ("clear", " ")]
        if not raw_names or "all" in raw_names:
            return "unilab_clear_workspace(globals())"
        names = [self._escape_name(n) for n in raw_names]
        quoted = [f"'{n}'" for n in names]
        return f"unilab_clear_variables(globals(), [{', '.join(quoted)}])"
        
    def global_stmt(self, items):
        names = [self._escape_name(str(i)) for i in items if str(i) != "global"]
        for n in names: self.globals.add(n)
        return f"global {', '.join(names)}"
        
    def import_stmt(self, items): return f"import {items[1]}"
    def export_stmt(self, items): return f"# export {items[1]}"
    def atom_group(self, items): return str(items[1])

class UniLabTranspiler:
    def __init__(self):
        self.parser = Lark(UniLab_GRAMMAR, parser='earley', ambiguity='resolve')
        self.transformer = UniLabToPython()
        self._cache = {}
        self._cache_limit = 100

    def transpile(self, code: str):
        # Key cache directly on code string to avoid hash collisions
        if code in self._cache:
            cached_code, cached_called, cached_paths = self._cache[code]
            return cached_code, set(cached_called), set(cached_paths)

        try:
            preprocessed = _disambiguate_transposes(code)
            tree = self.parser.parse(preprocessed + "\n")
            self.transformer.variables = set()
            self.transformer.globals = set()
            self.transformer.called_functions = set()
            self.transformer.added_paths = set()
            self.transformer.functions = []
            self.transformer._switch_depth = 0
            result = self.transformer.transform(tree)
            
            if self.transformer.functions:
                final_code = "\n\n".join(self.transformer.functions) + ("\n\n" + str(result) if str(result).strip() else "")
            else:
                final_code = str(result)
            transpiled = (final_code, set(self.transformer.called_functions), set(self.transformer.added_paths))
            
            # Simple FIFO/LRU-ish cache management
            if len(self._cache) >= self._cache_limit:
                self._cache.pop(next(iter(self._cache)))
            
            self._cache[code] = transpiled
            return final_code, set(transpiled[1]), set(transpiled[2])
        except Exception as e:
            raise e
