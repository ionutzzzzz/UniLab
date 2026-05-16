from lark import Lark, Transformer, v_args, Tree
import numpy as np

# EBNF Grammar for a subset of UniLab
UniLab_GRAMMAR = r"""
    start: (stmt_with_sep | separator)*

    ?stmt_with_sep: statement separator -> stmt_sep
                  | statement           -> stmt_no_sep

    ?statement: if_stmt
              | for_stmt
              | while_stmt
              | switch_stmt
              | try_stmt
              | global_stmt
              | function_def
              | assignment
              | clear_stmt
              | command_call
              | expr_stmt

    separator: SEMI | COMMA | NEWLINE

    assignment: lhs EQ expression -> assignment_stmt
    expr_stmt: expression -> expr_stmt

    ?lhs: qualified_name LPAR call_args RPAR -> indexed_lhs
        | qualified_name LBRACE call_args RBRACE -> cell_indexed_lhs
        | qualified_name -> single_lhs
        | LBRACKET qualified_name (COMMA qualified_name)* RBRACKET -> multi_lhs

    clear_stmt: CLEAR (qualified_name | "all")*

    command_call: qualified_name (qualified_name | STRING | NUMBER)+

    if_stmt: IF expression block elseif_clause* else_clause? END
    elseif_clause: ELSEIF expression block
    else_clause: ELSE block
    
    for_stmt: FOR identifier EQ expression block END
    while_stmt: WHILE expression block END
    
    switch_stmt: SWITCH expression case_clause* otherwise_clause? END
    case_clause: CASE expression block
    otherwise_clause: OTHERWISE block
    
    try_stmt: TRY block (CATCH identifier? block)? END

    global_stmt: GLOBAL simple_name (COMMA? simple_name)*

    function_def.10: "function" [function_ret] simple_name "(" [arg_list] ")" block "end"
    function_ret: ret_list EQ
    ret_list: simple_name -> single_ret
            | LBRACKET (simple_name (COMMA simple_name)*)? RBRACKET -> multi_ret
    arg_list: simple_name (COMMA simple_name)*

    block: (stmt_with_sep | separator)*

    ?expression: logical_or

    ?logical_or: logical_and
               | logical_or OR_OP logical_and -> or_op

    ?logical_and: comparison
                | logical_and AND_OP comparison -> and_and_op

    ?comparison: range_expr
               | comparison EQ_OP range_expr -> eq
               | comparison NE_OP range_expr  -> ne
               | comparison LT_OP range_expr  -> lt
               | comparison GT_OP range_expr  -> gt
               | comparison LE_OP range_expr -> le
               | comparison GE_OP range_expr -> ge

    ?range_expr: add_expr
               | add_expr COLON add_expr              -> range2
               | add_expr COLON add_expr COLON add_expr -> range3

    ?add_expr: term
             | add_expr PLUS term   -> add
             | add_expr MINUS term   -> sub

    ?term: factor
         | term MUL factor           -> mul
         | term DIV factor           -> div
         | term DOT_MUL factor       -> dot_mul
         | term DOT_DIV factor       -> dot_div

    ?factor: power
           | MINUS factor            -> neg
           | NOT_OP factor           -> not_op

    ?power: atom
          | power POW atom           -> pow
          | power DOT_POW atom       -> dot_pow
          | power TRANSPOSE          -> transpose

    ?atom: NUMBER                    -> number
         | STRING                    -> string
         | function_call
         | cell_indexing
         | qualified_name            -> var
         | LPAR expression RPAR      -> atom_group
         | matrix
         | cell_array

    matrix: LBRACKET row (SEMI row)* RBRACKET
    row: expression (COMMA? expression)*
    
    cell_array: LBRACE row (SEMI row)* RBRACE

    cell_indexing.2: qualified_name LBRACE call_args? RBRACE

    function_call.2: qualified_name LPAR call_args? RPAR
    ?call_arg: expression
             | COLON -> colon_expr
    call_args: call_arg (COMMA call_arg)*

    FUNCTION.2: "function"
    END.2: "end"
    IF.2: "if"
    ELSEIF.2: "elseif"
    ELSE.2: "else"
    FOR.2: "for"
    WHILE.2: "while"
    SWITCH.2: "switch"
    CASE.2: "case"
    OTHERWISE.2: "otherwise"
    TRY.2: "try"
    CATCH.2: "catch"
    GLOBAL.2: "global"
    CLEAR.2: "clear"

    EQ: "="
    PLUS: "+"
    MINUS: "-"
    MUL: "*"
    DIV: "/"
    DOT_MUL: ".*"
    DOT_DIV: "./"
    POW: "^"
    DOT_POW: ".^"
    TRANSPOSE: "'"
    LPAR: "("
    RPAR: ")"
    LBRACKET: "["
    RBRACKET: "]"
    LBRACE: "{"
    RBRACE: "}"
    COMMA: ","
    SEMI: ";"
    COLON: ":"
    DOT: "."
    OR_OP: "||" | "|"
    AND_OP: "&&" | "&"
    EQ_OP: "=="
    NE_OP: "~="
    LT_OP: "<"
    GT_OP: ">"
    LE_OP: "<="
    GE_OP: ">="
    NOT_OP: "~"

    qualified_name: IDENTIFIER (DOT IDENTIFIER)*
    simple_name: IDENTIFIER
    identifier: IDENTIFIER

    IDENTIFIER: /(?!function|end|if|elseif|else|for|while|switch|case|otherwise|try|catch|global|clear)[a-zA-Z_][a-zA-Z0-9_]*/

    %import common.CNAME
    %import common.NUMBER
    %import common.WS_INLINE
    %import common.ESCAPED_STRING
    STRING: "'" ("''"|/[^'\n\r]/)* "'"
    NEWLINE: (/\r?\n/ WS_INLINE*)+
    
    %ignore WS_INLINE
    %ignore /%.*/
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
        
        def flatten(items):
            res = []
            if isinstance(items, str): return [items]
            if not isinstance(items, (list, tuple, set)): return [str(items)]
            for i in items:
                if isinstance(i, (list, tuple, set)): res.extend(flatten(i))
                elif i is not None: res.append(str(i))
            return res
            
        flat_lines = []
        for l in flatten(lines):
            flat_lines.extend(l.split('\n'))
            
        res = ["    " + l if l.strip() else l for l in flat_lines]
        if not res: return ["    pass"]
        return res

    def number(self, n): return str(n[0])
    def string(self, s):
        content = str(s[0])[1:-1].replace("''", "'")
        return f"'{content}'"
    def colon_expr(self, items): return "slice(None)"
    def _escape_name(self, name):
        keywords = {
            'False', 'None', 'True', 'and', 'as', 'assert', 'async', 'await', 
            'break', 'class', 'continue', 'def', 'del', 'elif', 'else', 
            'except', 'finally', 'for', 'from', 'global', 'if', 'import', 
            'in', 'is', 'lambda', 'nonlocal', 'not', 'or', 'pass', 'raise', 
            'return', 'try', 'while', 'with', 'yield'
        }
        if name in keywords:
            return f"{name}_"
        return name

    def identifier(self, i):
        return self._escape_name(str(i[0]))

    def qualified_name(self, items):
        if len(items) == 1:
            return self._escape_name(str(items[0]))
        
        parts = [self._escape_name(str(i)) for i in items if str(i) != "."]
        res = parts[0]
        for p in parts[1:]:
            res = f"unilab_get({res}, '{p}')"
        return res

    def simple_name(self, items):
        return self._escape_name(str(items[0]))

    def var(self, items):
        name = items[0] 
        name_str = str(name)
        if name_str == "nargin":
            return "nargin"
            
        if '(' in name_str:
            base_name = name_str.split('(')[-1].split(',')[0].strip("'")
        else:
            base_name = name_str
        self.variables.add(base_name)
        self.called_functions.add(base_name)
        return name

    def single_lhs(self, items): return items[0]
    def multi_lhs(self, items):
        return [str(i) for i in items if str(i) not in ["[", "]", ","]]

    def indexed_lhs(self, items):
        target = items[0]
        args = []
        for i in items[1:]:
            if str(i) not in ["(", ")"]:
                args = i
                break
        arg_str = ", ".join(args) if isinstance(args, list) else str(args)
        return {"type": "indexed_lhs", "target": target, "args": arg_str}

    def cell_indexed_lhs(self, items):
        target = items[0]
        args = []
        for i in items[1:]:
            if str(i) not in ["{", "}"]:
                args = i
                break
        arg_str = ", ".join(args) if isinstance(args, list) else str(args)
        return {"type": "cell_indexed_lhs", "target": target, "args": arg_str}

    def clear_stmt(self, items):
        names = [str(i) for i in items if str(i) not in [";", "clear"]]
        if not names or 'all' in names:
            return "unilab_clear_workspace(globals())"
        vars_to_clear = [f"'{n}'" for n in names]
        return f"unilab_clear_variables(globals(), [{', '.join(vars_to_clear)}])"

    def command_call(self, items):
        name = str(items[0])
        self.called_functions.add(name)
        args = [f"'{a}'" for a in items[1:] if str(a) not in [";", ","]]
        return f"{name}({', '.join(args)})"

    def separator(self, items):
        return str(items[0])

    def stmt_sep(self, items):
        stmt = items[0]
        sep = items[1]
        has_semi = (str(sep) == ";")
        return self._process_stmt(stmt, has_semi)

    def stmt_no_sep(self, items):
        return self._process_stmt(items[0], False)

    def _process_stmt(self, stmt, has_semi):
        if isinstance(stmt, dict):
            if stmt.get("type") == "assignment":
                lhs = stmt["lhs"]
                expr = stmt["expr"]
                if isinstance(lhs, dict) and (lhs.get("type") == "indexed_lhs" or lhs.get("type") == "cell_indexed_lhs"):
                    stmt_str = f"unilab_set({lhs['target']}, {expr}, {lhs['args']})"
                    print_target = lhs['target']
                elif isinstance(lhs, list):
                    for n in lhs: self.variables.add(str(n))
                    stmt_str = f"({', '.join([str(n) for n in lhs])}) = {expr}"
                    print_target = f"[{', '.join([str(n) for n in lhs])}]"
                else:
                    self.variables.add(str(lhs))
                    stmt_str = f"{lhs} = {expr}"
                    print_target = str(lhs)
                
                if not has_semi:
                    print_target_esc = print_target.replace("'", "\\'")
                    if isinstance(lhs, list):
                        return f"{stmt_str}; unilab_print_var('{print_target_esc}', ({', '.join([str(n) for n in lhs])}))"
                    else:
                        return f"{stmt_str}; unilab_print_var('{print_target_esc}', {print_target})"
                return stmt_str
            
            if stmt.get("type") == "expr":
                expr = stmt["expr"]
                if not has_semi:
                    expr_esc = str(expr).replace("'", "\\'")
                    return f"ans = unilab_print_and_save_ans('{expr_esc}', {expr})"
                return str(expr)
        
        if isinstance(stmt, list):
            return "\n".join(stmt)
        return str(stmt)

    def block(self, items):
        flattened = []
        for s in items:
            if isinstance(s, list):
                flattened.extend(s)
            elif isinstance(s, str):
                if s.strip() and s not in [";", ",", "\n"]:
                    flattened.append(s)
            elif s is not None:
                flattened.append(str(s))
        return flattened

    def start(self, items):
        lines = self.block(items)
        return "\n".join(lines)

    def assignment_stmt(self, items):
        return {"type": "assignment", "lhs": items[0], "expr": items[2]}

    def expr_stmt(self, items):
        return {"type": "expr", "expr": items[0]}

    def add(self, items): return f"({items[0]} + {items[2]})"
    def sub(self, items): return f"({items[0]} - {items[2]})"
    def mul(self, items): return f"unilab_mul({items[0]}, {items[2]})"
    def div(self, items): return f"unilab_div({items[0]}, {items[2]})"
    def dot_mul(self, items): return f"({items[0]} * {items[2]})"
    def dot_div(self, items): return f"({items[0]} / {items[2]})"
    def pow(self, items): return f"unilab_pow({items[0]}, {items[2]})"
    def dot_pow(self, items): return f"({items[0]} ** {items[2]})"
    def transpose(self, items): return f"{items[0]}.T"
    def neg(self, items): return f"-{items[1]}"
    def not_op(self, items): return f"(not {items[1]})"
    def or_op(self, items): return f"unilab_or({items[0]}, {items[2]})"
    def and_and_op(self, items): return f"unilab_and({items[0]}, {items[2]})"
    def eq(self, items): return f"({items[0]} == {items[2]})"
    def ne(self, items): return f"({items[0]} != {items[2]})"
    def lt(self, items): return f"({items[0]} < {items[2]})"
    def gt(self, items): return f"({items[0]} > {items[2]})"
    def le(self, items): return f"({items[0]} <= {items[2]})"
    def ge(self, items): return f"({items[0]} >= {items[2]})"

    def atom_group(self, items):
        return items[1]

    def matrix(self, items):
        actual_rows = [r for r in items if str(r) not in ["[", "]", ";"]]
        row_strs = []
        for r in actual_rows:
            if isinstance(r, list):
                row_strs.append(f"[{', '.join(r)}]")
        return f"unilab_matrix_concat({', '.join(row_strs)})"

    def cell_array(self, items):
        actual_rows = [r for r in items if str(r) not in ["{", "}", ";"]]
        row_strs = []
        for r in actual_rows:
            if isinstance(r, list):
                row_strs.extend(r)
        return f"unilab_cell_concat({', '.join(row_strs)})"

    def row(self, items):
        return [str(i) for i in items if str(i) != ","]

    def range2(self, items): return f"np.arange({items[0]}, {items[2]} + 1)"
    def range3(self, items): return f"np.arange({items[0]}, {items[4]} + {items[2]}, {items[2]})"

    def call_args(self, items):
        return [str(i) for i in items if str(i) != ","]

    def cell_indexing(self, items):
        name = str(items[0])
        self.called_functions.add(name)
        args = items[2] if len(items) > 3 else None
        arg_str = ", ".join(args) if isinstance(args, list) else (str(args) if args is not None else "")
        return f"unilab_call({name}, {arg_str})"

    def function_call(self, items):
        name = str(items[0])
        self.called_functions.add(name)
        if name == "addpath" and len(items) > 2:
            args = items[2]
            if isinstance(args, list):
                for a in args:
                    if str(a).startswith("'") and str(a).endswith("'"):
                        self.added_paths.add(str(a)[1:-1])

        args = items[2] if len(items) > 3 else None
        if name == "pi" and not args: return "np.pi"
        arg_str = ", ".join(args) if isinstance(args, list) else (str(args) if args is not None else "")
        return f"unilab_call({name}, {arg_str})"

    def if_stmt(self, items):
        # items: ['if', expression, block, (elseif_clause)*, (else_clause)?, 'end']
        cond = items[1]
        block = items[2]
        lines = [f"if {cond}:"]
        lines.extend(self._indent(block))
        for i in range(3, len(items)):
            item = items[i]
            if str(item) == "end": break
            if isinstance(item, list):
                lines.extend(item)
        return lines

    def elseif_clause(self, items):
        # items: ['elseif', expression, block]
        cond = items[1]
        block = items[2]
        return [f"elif {cond}:"] + self._indent(block)

    def else_clause(self, items):
        # items: ['else', block]
        block = items[1]
        return ["else:"] + self._indent(block)

    def for_stmt(self, items):
        # items: ['for', var, '=', expr, block, 'end']
        var = items[1]
        expr = items[3]
        block = items[4]
        self.variables.add(str(var))
        return [f"for {var} in {expr}:"] + self._indent(block)

    def while_stmt(self, items):
        # items: ['while', expr, block, 'end']
        cond = items[1]
        block = items[2]
        return [f"while {cond}:"] + self._indent(block)

    def switch_stmt(self, items):
        expr = items[1]
        self._switch_depth += 1
        var_name = f"_sw_{self._switch_depth}"
        lines = [f"{var_name} = {expr}"]
        first = True
        for i in range(2, len(items) - 1):
            clause = items[i]
            if str(clause) in [";", ",", "\n"] or clause is None: continue
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
        # items: [CASE, expression, block]
        expr = items[1]
        block = items[2]
        return [f"elif _sw_tmp == {expr}:"] + self._indent(block)

    def otherwise_clause(self, items):
        # items: [OTHERWISE, block]
        block = items[1]
        return ["else:"] + self._indent(block)

    def try_stmt(self, items):
        lines = ["try:"]
        block = items[1]
        lines.extend(self._indent(block))
        idx = 2
        if idx < len(items) and str(items[idx]) == "catch":
            idx += 1
            err_var = None
            if not str(items[idx]) == "end" and not isinstance(items[idx], list):
                err_var = items[idx]
                idx += 1
            catch_block = items[idx]
            if err_var:
                lines.append(f"except Exception as {err_var}:")
            else:
                lines.append("except Exception:")
            lines.extend(self._indent(catch_block))
        return lines

    def global_stmt(self, items):
        names = [str(i) for i in items[1:]]
        for n in names: self.globals.add(n)
        return [f"global {', '.join(names)}"]

    def function_ret(self, items):
        return items[0]

    def single_ret(self, items): return str(items[0])
    def multi_ret(self, items):
        return [str(i) for i in items if str(i) not in ["[", "]", ","]]

    def arg_list(self, items):
        return [str(i) for i in items if str(i) != ","]

    def function_def(self, items):
        # items: ['function', ret?, name, '(', args?, ')', block, 'end']
        filtered = [i for i in items if str(i) not in ["function", "(", ")", "end"]]
        if len(filtered) == 4:
            rets, name, args, block = filtered
        elif len(filtered) == 3:
            if isinstance(filtered[0], (str, list)) and not isinstance(filtered[1], list):
                 rets, name, args, block = filtered[0], filtered[1], None, filtered[2]
            else:
                 rets, name, args, block = None, filtered[0], filtered[1], filtered[2]
        else:
            rets, name, args, block = None, filtered[0], None, filtered[1]

        arg_str = ""
        if args:
            if isinstance(args, list): arg_str = ", ".join(args)
            else: arg_str = str(args)

        lines = [f"def {name}({arg_str}):"]
        lines.append("    global ans")
        if args:
            arg_names = [str(a) for a in (args if isinstance(args, list) else [args])]
            arg_names = [a for a in arg_names if a not in [",", ";"]]
            lines.append(f"    nargin = unilab_nargin_sum(1 for x in [{', '.join(arg_names)}] if x is not None)")
        else:
            lines.append("    nargin = 0")
        lines.extend(self._indent(block))
        if rets:
            if isinstance(rets, list): lines.append(f"    return ({', '.join(rets)})")
            else: lines.append(f"    return {rets}")
        return lines

class UniLabTranspiler:
    def __init__(self):
        self.parser = Lark(UniLab_GRAMMAR, parser='earley')
        self.transformer = UniLabToPython()

    def transpile(self, matlab_code):
        self.transformer.variables = set()
        self.transformer.globals = set()
        self.transformer.called_functions = set()
        self.transformer.added_paths = set()
        tree = self.parser.parse(matlab_code)
        result = self.transformer.transform(tree)
        return str(result), self.transformer.called_functions, self.transformer.added_paths

def transpile(UniLab_code):
    transpiler = UniLabTranspiler()
    return transpiler.transpile(UniLab_code)

if __name__ == "__main__":
    t = UniLabTranspiler()
    test_code = """
    function [y] = my_func(x)
        y = x * 2;
    end
    """
    print(t.transpile(test_code))
