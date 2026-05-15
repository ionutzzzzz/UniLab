from lark import Lark, Transformer, v_args, Tree
import numpy as np

# EBNF Grammar for a subset of MATLAB
MATLAB_GRAMMAR = r"""
    start: statement*

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
              | expression SEMI -> expr_stmt
              | expression -> expr_stmt_no_semi

    assignment: lhs EQ expression SEMI? -> assignment_stmt
    ?lhs: qualified_name LPAR call_args RPAR -> indexed_lhs
        | qualified_name -> single_lhs
        | LBRACKET qualified_name (COMMA qualified_name)* RBRACKET -> multi_lhs

    clear_stmt: CLEAR (qualified_name | "all")* SEMI?

    command_call: qualified_name qualified_name+ SEMI?

    if_stmt: IF expression block elseif_clause* else_clause? END
    elseif_clause: ELSEIF expression block
    else_clause: ELSE block
    
    for_stmt: FOR identifier EQ expression block END
    while_stmt: WHILE expression block END
    
    switch_stmt: SWITCH expression case_clause* otherwise_clause? END
    case_clause: CASE expression block
    otherwise_clause: OTHERWISE block
    
    try_stmt: TRY block CATCH identifier? block END
    
    global_stmt: GLOBAL simple_name (COMMA? simple_name)* SEMI?

    function_def.10: "function" [function_ret] simple_name "(" [arg_list] ")" block "end"
    function_ret: ret_list EQ
    ret_list: simple_name -> single_ret
            | LBRACKET simple_name (COMMA simple_name)* RBRACKET -> multi_ret
    arg_list: simple_name (COMMA simple_name)*

    block: statement*

    ?expression: logical_or

    ?logical_or: logical_and
               | logical_or OR_OP logical_and -> or_op

    ?logical_and: comparison
                | logical_and AND_OP comparison -> and_op

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
         | qualified_name            -> var
         | LPAR expression RPAR      -> atom_group
         | matrix

    matrix: LBRACKET row (SEMI row)* RBRACKET
    row: expression (COMMA? expression)*

    function_call.2: qualified_name LPAR call_args? RPAR
    ?call_arg: expression
             | COLON -> colon_expr
    call_args: call_arg (COMMA call_arg)*

    qualified_name: CNAME (DOT CNAME)*
    simple_name: CNAME
    identifier: CNAME

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

    %import common.CNAME
    %import common.NUMBER
    %import common.WS
    %import common.ESCAPED_STRING
    STRING: "'" ("''"|/[^'\n\r]/)* "'"
    
    %ignore WS
    %ignore /%.*/
"""

class MatlabToPython(Transformer):
    def __init__(self):
        self.variables = set()
        self.globals = set()
        self.called_functions = set()
        self.added_paths = set()
        self._switch_depth = 0

    def _indent(self, lines):
        if not lines: return ["    pass"]
        if isinstance(lines, str): lines = [lines]
        return ["    " + line for line in lines]

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
        
        # Attribute access: a.b.c -> unilab_get(unilab_get(a, 'b'), 'c')
        parts = [self._escape_name(str(i)) for i in items if str(i) != "."]
        res = parts[0]
        for p in parts[1:]:
            res = f"unilab_get({res}, '{p}')"
        return res

    def simple_name(self, items):
        return self._escape_name(str(items[0]))

    def var(self, items):
        name = items[0] # qualified_name or similar
        # if it's already unilab_get(...) it might be complex
        # but for tracking we just want the base
        base_name = str(name).split('(')[-1].split(',')[0].strip("'")
        self.variables.add(base_name)
        self.called_functions.add(base_name)
        return name

    def single_lhs(self, items): return items[0]
    def multi_lhs(self, items):
        return [str(i) for i in items if str(i) not in ["[", "]", ","]]

    def indexed_lhs(self, items):
        # items might contain ( and )
        target = items[0]
        args = []
        for i in items[1:]:
            if str(i) not in ["(", ")"]:
                args = i
                break
        
        arg_str = ", ".join(args) if isinstance(args, list) else str(args)
        return {"type": "indexed_lhs", "target": target, "args": arg_str}

    def assignment(self, items):
        lhs = items[0]
        expr = items[2]
        if isinstance(lhs, dict) and lhs.get("type") == "indexed_lhs":
            return f"unilab_set({lhs['target']}, {expr}, {lhs['args']})"
        if isinstance(lhs, list):
            for n in lhs: self.variables.add(str(n))
            return f"({', '.join([str(n) for n in lhs])}) = {expr}"
        else:
            self.variables.add(str(lhs))
            return f"{lhs} = {expr}"

    def clear_stmt(self, items):
        names = [str(i) for i in items if str(i) not in [";", "clear"]]
        if not names or 'all' in names:
            return "unilab_clear_workspace(globals())"
        vars_to_clear = [f"'{n}'" for n in names]
        return f"unilab_clear_variables(globals(), [{', '.join(vars_to_clear)}])"

    def command_call(self, items):
        name = str(items[0])
        self.called_functions.add(name)
        args = [f"'{a}'" for a in items[1:]]
        return f"{name}({', '.join(args)})"

    def expr_stmt(self, items): return items[0]
    
    def expr_stmt_no_semi(self, items):
        expr = items[0]
        # Wrap expression in unilab_print_and_save_ans
        return f"global ans; ans = unilab_print_and_save_ans('{expr}', {expr})"

    def assignment_stmt(self, items):
        # items: [lhs, EQ, expression, SEMI?]
        lhs = items[0]
        expr = items[2]
        
        has_semi = False
        if len(items) > 3:
            has_semi = True
        
        if isinstance(lhs, dict) and lhs.get("type") == "indexed_lhs":
            stmt = f"unilab_set({lhs['target']}, {expr}, {lhs['args']})"
        elif isinstance(lhs, list):
            for n in lhs: self.variables.add(str(n))
            stmt = f"({', '.join([str(n) for n in lhs])}) = {expr}"
        else:
            self.variables.add(str(lhs))
            stmt = f"{lhs} = {expr}"
            
        if not has_semi:
            if isinstance(lhs, list):
                # For multi-lhs, we might want to print each? 
                # MATLAB prints the first one usually or a summary.
                # Let's just print the whole tuple for now.
                lhs_str = f"[{', '.join([str(n) for n in lhs])}]"
                return f"{stmt}; unilab_print_var('{lhs_str}', ({', '.join([str(n) for n in lhs])}))"
            else:
                return f"{stmt}; unilab_print_var('{lhs}', {lhs})"
        return stmt

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
    def and_op(self, items): return f"unilab_and({items[0]}, {items[2]})"
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
        return f"np.array([{', '.join(row_strs)}])"

    def row(self, items):
        return [str(i) for i in items if str(i) != ","]

    def range2(self, items): return f"np.arange({items[0]}, {items[2]} + 1)"
    def range3(self, items): return f"np.arange({items[0]}, {items[4]} + {items[2]}, {items[2]})"

    def function_call(self, items):
        name = str(items[0])
        self.called_functions.add(name)
        
        # Track addpath calls for pre-resolution
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

    def call_args(self, items):
        return [str(i) for i in items if str(i) != ","]

    def block(self, items):
        flattened = []
        for s in items:
            if isinstance(s, list):
                flattened.extend(s)
            elif s is not None:
                flattened.append(s)
        return flattened

    def start(self, items):
        def flatten(items):
            res = []
            for i in items:
                if isinstance(i, list):
                    res.extend(flatten(i))
                elif i is not None:
                    res.append(str(i))
            return res
        return "\n".join(flatten(items))

    def if_stmt(self, items):
        # items: [IF, expression, block, elseif_clause*, else_clause?, END]
        cond = items[1]
        block = items[2]
        lines = [f"if {cond}:"]
        lines.extend(self._indent(block))
        for i in range(3, len(items) - 1):
            clause = items[i]
            if isinstance(clause, list):
                lines.extend(clause)
        return lines

    def elseif_clause(self, items):
        # items: [ELSEIF, expression, block]
        return [f"elif {items[1]}:"] + self._indent(items[2])

    def else_clause(self, items):
        # items: [ELSE, block]
        return ["else:"] + self._indent(items[1])

    def for_stmt(self, items):
        # items: [FOR, identifier, EQ, expression, block, END]
        return [f"for {items[1]} in {items[3]}:"] + self._indent(items[4])

    def while_stmt(self, items):
        # items: [WHILE, expression, block, END]
        return [f"while {items[1]}:"] + self._indent(items[2])

    def switch_stmt(self, items):
        # items: [SWITCH, expression, case_clause*, otherwise_clause?, END]
        expr = items[1]
        self._switch_depth += 1
        var_name = f"_sw_{self._switch_depth}"
        lines = [f"{var_name} = {expr}"]
        
        first = True
        for i in range(2, len(items) - 1):
            clause = items[i]
            if clause is None: continue
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
        return [f"elif _sw_tmp == {items[1]}:"] + self._indent(items[2])

    def otherwise_clause(self, items):
        # items: [OTHERWISE, block]
        return ["else:"] + self._indent(items[1])

    def try_stmt(self, items):
        # items: [TRY, block, CATCH, identifier?, block, END]
        lines = ["try:"]
        lines.extend(self._indent(items[1]))
        
        # Search for catch block
        catch_idx = -1
        for idx, item in enumerate(items):
            if str(item) == "catch":
                catch_idx = idx
                break
        
        if catch_idx != -1:
            if catch_idx + 2 < len(items) and str(items[catch_idx+2]) != "end":
                err_var = items[catch_idx+1]
                catch_block = items[catch_idx+2]
                lines.append(f"except Exception as {err_var}:")
            else:
                catch_block = items[catch_idx+1]
                lines.append("except Exception:")
            lines.extend(self._indent(catch_block))
        return lines

    def global_stmt(self, items):
        # items: [GLOBAL, identifier, identifier, ...]
        names = [str(i) for i in items[1:]]
        for n in names: self.globals.add(n)
        return [f"global {', '.join(names)}"]

    def function_ret(self, items):
        # items: [ret_list, EQ]
        return items[0]

    def single_ret(self, items): return str(items[0])
    def multi_ret(self, items):
        # items: [LBRACKET, identifier, COMMA, identifier, ..., RBRACKET]
        return [str(i) for i in items if str(i) not in ["[", "]", ","]]

    def arg_list(self, items):
        return [str(i) for i in items if str(i) != ","]

    def function_def(self, items):
        # items: [function_ret?, simple_name, arg_list?, block]
        # print(f"DEBUG items: {[str(i) for i in items]}")
        
        rets = items[0]
        name = items[1]
        args = items[2]
        block = items[3]

        arg_str = ""
        if args:
            if isinstance(args, list): arg_str = ", ".join(args)
            else: arg_str = str(args)

        lines = [f"def {name}({arg_str}):"]
        lines.extend(self._indent(block))
        if rets:
            if isinstance(rets, list): lines.append(f"    return ({', '.join(rets)})")
            else: lines.append(f"    return {rets}")
        return lines

class MatlabTranspiler:
    def __init__(self):
        self.parser = Lark(MATLAB_GRAMMAR, parser='earley')
        self.transformer = MatlabToPython()

    def transpile(self, matlab_code):
        self.transformer.variables = set()
        self.transformer.globals = set()
        self.transformer.called_functions = set()
        self.transformer.added_paths = set()
        tree = self.parser.parse(matlab_code)
        result = self.transformer.transform(tree)
        return str(result), self.transformer.called_functions, self.transformer.added_paths

def transpile(matlab_code):
    transpiler = MatlabTranspiler()
    return transpiler.transpile(matlab_code)

if __name__ == "__main__":
    t = MatlabTranspiler()
    test_code = """
    function [y] = my_func(x)
        y = x * 2;
    end
    """
    print(t.transpile(test_code))
