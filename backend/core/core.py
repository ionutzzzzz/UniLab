from lark import Lark, Transformer, v_args
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
              | expression SEMI? -> expr_stmt

    assignment: lhs EQ expression SEMI?
    ?lhs: identifier -> single_lhs
        | LBRACKET identifier (COMMA identifier)* RBRACKET -> multi_lhs

    clear_stmt: "clear" (identifier | "all")* SEMI?

    command_call: identifier identifier+ SEMI?

    if_stmt: "if" expression block elseif_clause* else_clause? "end"
    elseif_clause: "elseif" expression block
    else_clause: "else" block
    
    for_stmt: "for" identifier EQ expression block "end"
    while_stmt: "while" expression block "end"
    
    switch_stmt: "switch" expression case_clause* otherwise_clause? "end"
    case_clause: "case" expression block
    otherwise_clause: "otherwise" block
    
    try_stmt: "try" block "catch" identifier? block "end"
    
    global_stmt: "global" identifier (COMMA? identifier)* SEMI?

    function_def: "function" function_ret? identifier LPAR arg_list? RPAR block "end"
    function_ret: ret_list EQ
    ret_list: identifier -> single_ret
            | LBRACKET identifier (COMMA identifier)* RBRACKET -> multi_ret
    arg_list: identifier (COMMA identifier)*

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

    ?atom: NUMBER                    -> number
         | STRING                    -> string
         | function_call
         | identifier                -> var
         | LPAR expression RPAR      -> atom_group
         | matrix

    matrix: LBRACKET row (SEMI row)* RBRACKET
    row: expression (COMMA? expression)*

    function_call: identifier LPAR call_args? RPAR
    call_args: expression (COMMA expression)*

    identifier: CNAME

    EQ: "="
    PLUS: "+"
    MINUS: "-"
    MUL: "*"
    DIV: "/"
    DOT_MUL: ".*"
    DOT_DIV: "./"
    POW: "^"
    DOT_POW: ".^"
    LPAR: "("
    RPAR: ")"
    LBRACKET: "["
    RBRACKET: "]"
    COMMA: ","
    SEMI: ";"
    COLON: ":"
    OR_OP: "||"
    AND_OP: "&&"
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
    STRING: "'" ("''"|/[^']/)* "'"
    
    %ignore WS
    %ignore /%.*/
"""

class MatlabToPython(Transformer):
    def __init__(self):
        self.variables = set()
        self.globals = set()
        self._switch_depth = 0

    def _indent(self, lines):
        if not lines: return ["    pass"]
        return ["    " + line for line in lines]

    def number(self, n): return str(n[0])
    def string(self, s):
        content = str(s[0])[1:-1].replace("''", "'")
        return f"'{content}'"
    def identifier(self, i): return str(i[0])

    def var(self, items):
        name = str(items[0])
        if name == "pi": return "np.pi"
        self.variables.add(name)
        return name

    def single_lhs(self, items): return str(items[0])
    def multi_lhs(self, items):
        return [str(i) for i in items if str(i) not in ["[", "]", ","]]

    def assignment(self, items):
        lhs = items[0]
        expr = items[2]
        if isinstance(lhs, list):
            for n in lhs: self.variables.add(n)
            return f"({', '.join(lhs)}) = {expr}"
        else:
            self.variables.add(lhs)
            return f"{lhs} = {expr}"

    def clear_stmt(self, items):
        names = [str(i) for i in items if str(i) not in [";", "clear"]]
        if not names or 'all' in names:
            return "unilab_clear_workspace(globals())"
        vars_to_clear = [f"'{n}'" for n in names]
        return f"unilab_clear_variables(globals(), [{', '.join(vars_to_clear)}])"

    def command_call(self, items):
        name = items[0]
        args = [f"'{a}'" for a in items[1:]]
        return f"{name}({', '.join(args)})"

    def expr_stmt(self, items): return items[0]

    def add(self, items): return f"({items[0]} + {items[2]})"
    def sub(self, items): return f"({items[0]} - {items[2]})"
    def mul(self, items): return f"unilab_mul({items[0]}, {items[2]})"
    def div(self, items): return f"unilab_div({items[0]}, {items[2]})"
    def dot_mul(self, items): return f"({items[0]} * {items[2]})"
    def dot_div(self, items): return f"({items[0]} / {items[2]})"
    def pow(self, items): return f"unilab_pow({items[0]}, {items[2]})"
    def dot_pow(self, items): return f"({items[0]} ** {items[2]})"
    def neg(self, items): return f"-{items[1]}"
    def not_op(self, items): return f"(not {items[1]})"
    def or_op(self, items): return f"({items[0]} or {items[2]})"
    def and_op(self, items): return f"({items[0]} and {items[2]})"
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
        name = items[0]
        args = items[2] if len(items) > 3 else None
        if name == "pi" and not args: return "np.pi"
        arg_str = ", ".join(args) if isinstance(args, list) else (str(args) if args is not None else "")
        return f"{name}({arg_str})"

    def call_args(self, items):
        return [str(i) for i in items if str(i) != ","]

    def block(self, items):
        raw_flattened = []
        for s in items:
            if isinstance(s, list): raw_flattened.extend(s)
            elif s is not None: raw_flattened.append(s)
        
        flattened = []
        i = 0
        while i < len(raw_flattened):
            s = raw_flattened[i]
            if i + 1 < len(raw_flattened) and isinstance(s, str) and isinstance(raw_flattened[i+1], str):
                if raw_flattened[i+1].startswith("("):
                    if s.isidentifier() or s.endswith("sin") or s.endswith("disp") or s.endswith("plot") or "=" in s:
                        flattened.append(f"{s}{raw_flattened[i+1]}")
                        i += 2
                        continue
                if s in ["grid", "hold"]:
                    flattened.append(f"{s}('{raw_flattened[i+1]}')")
                    i += 2
                    continue
            flattened.append(s)
            i += 1
        return flattened

    def start(self, items):
        return "\n".join(self.block(items))

    def if_stmt(self, items):
        cond = items[1]
        block = items[2]
        lines = [f"if {cond}:"]
        lines.extend(self._indent(block))
        for i in range(3, len(items)-1):
            if isinstance(items[i], list): lines.extend(items[i])
        return lines

    def elseif_clause(self, items):
        return [f"elif {items[1]}:"] + self._indent(items[2])

    def else_clause(self, items):
        return ["else:"] + self._indent(items[1])

    def for_stmt(self, items):
        return [f"for {items[1]} in {items[3]}:"] + self._indent(items[4])

    def while_stmt(self, items):
        return [f"while {items[1]}:"] + self._indent(items[2])

    def switch_stmt(self, items):
        expr = items[1]
        self._switch_depth += 1
        var_name = f"_sw_{self._switch_depth}"
        lines = [f"{var_name} = {expr}"]
        
        first = True
        for i in range(2, len(items)-1):
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
        return [f"elif _sw_tmp == {items[1]}:"] + self._indent(items[2])

    def otherwise_clause(self, items):
        return ["else:"] + self._indent(items[1])

    def try_stmt(self, items):
        lines = ["try:"]
        lines.extend(self._indent(items[1]))
        catch_idx = items.index("catch")
        if catch_idx + 1 < len(items) and str(items[catch_idx+1]) != "end" and not isinstance(items[catch_idx+1], list):
            err_var = items[catch_idx+1]
            catch_block = items[catch_idx+2]
            lines.append(f"except Exception as {err_var}:")
        else:
            catch_block = items[catch_idx+1] if catch_idx + 1 < len(items) else []
            lines.append("except Exception:")
        
        lines.extend(self._indent(catch_block))
        return lines

    def global_stmt(self, items):
        names = []
        for i in range(1, len(items)):
            s = str(items[i])
            if s not in [";", ","]: names.append(s)
        for n in names: self.globals.add(n)
        return [f"global {', '.join(names)}"]

    def function_ret(self, items):
        return items[0]

    def single_ret(self, items): return str(items[0])
    def multi_ret(self, items): return [str(i) for i in items if str(i) not in ["[", "]", ","]]
    def arg_list(self, items): return [str(i) for i in items if str(i) != ","]

    def function_def(self, items):
        try:
            lpar_idx = items.index("(")
            rpar_idx = items.index(")")
            name = items[lpar_idx - 1]
            rets = None
            if lpar_idx >= 4 and str(items[lpar_idx-2]) == "=":
                rets = items[lpar_idx-3]
            args = items[lpar_idx+1] if rpar_idx > lpar_idx + 1 else None
            block = items[rpar_idx+1]
        except:
            name = "unknown"
            args = None
            block = []

        arg_str = ""
        if args:
            if isinstance(args, list): arg_str = ", ".join(args)
            else: arg_str = str(args)

        lines = [f"def {name}({arg_str}):"]
        for g in self.globals:
            lines.append(f"    global {g}")
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
        tree = self.parser.parse(matlab_code)
        result = self.transformer.transform(tree)
        return str(result)

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
