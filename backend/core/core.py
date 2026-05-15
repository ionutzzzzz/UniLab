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
              | expression ";"? -> expr_stmt

    assignment: lhs "=" expression ";"?
    ?lhs: identifier -> single_lhs
        | "[" identifier ("," identifier)* "]" -> multi_lhs

    if_stmt: "if" expression block elseif_clause* [else_clause] "end"
    elseif_clause: "elseif" expression block
    else_clause: "else" block
    
    for_stmt: "for" identifier "=" expression block "end"
    while_stmt: "while" expression block "end"
    
    switch_stmt: "switch" expression case_clause* [otherwise_clause] "end"
    case_clause: "case" expression block
    otherwise_clause: "otherwise" block
    
    try_stmt: "try" block "catch" [identifier] block "end"
    
    global_stmt: "global" identifier (","? identifier)* ";"?

    function_def: "function" [ret_list "="] identifier "(" [arg_list] ")" block "end"
    ret_list: identifier -> single_ret
            | "[" identifier ("," identifier)* "]" -> multi_ret
    arg_list: identifier ("," identifier)*

    block: statement*

    ?expression: logical_or

    ?logical_or: logical_and
               | logical_or "||" logical_and -> or_op

    ?logical_and: comparison
                | logical_and "&&" comparison -> and_op

    ?comparison: range_expr
               | comparison "==" range_expr -> eq
               | comparison "~=" range_expr -> ne
               | comparison "<" range_expr  -> lt
               | comparison ">" range_expr  -> gt
               | comparison "<=" range_expr -> le
               | comparison ">=" range_expr -> ge

    ?range_expr: add_expr
               | add_expr ":" add_expr              -> range2
               | add_expr ":" add_expr ":" add_expr -> range3

    ?add_expr: term
             | add_expr "+" term   -> add
             | add_expr "-" term   -> sub

    ?term: factor
         | term "*" factor           -> mul
         | term "/" factor           -> div
         | term ".*" factor          -> dot_mul
         | term "./" factor          -> dot_div

    ?factor: power
           | "-" factor              -> neg
           | "~" factor              -> not_op

    ?power: atom
          | power "^" atom           -> pow
          | power ".^" atom          -> dot_pow

    ?atom: NUMBER                    -> number
         | STRING                    -> string
         | function_call
         | identifier                -> var
         | "(" expression ")"
         | matrix

    matrix: "[" row (";" row)* "]"
    row: expression (","? expression)*

    function_call: identifier "(" [expression ("," expression)*] ")"

    identifier: CNAME

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
        # items: [lhs, "=", expr, semi?]
        lhs = items[0]
        expr = items[2]
        if isinstance(lhs, list):
            for n in lhs: self.variables.add(n)
            return f"({', '.join(lhs)}) = {expr}"
        else:
            self.variables.add(lhs)
            return f"{lhs} = {expr}"

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
        args = []
        for i in range(2, len(items)-1):
            if str(items[i]) != ",": args.append(str(items[i]))
        if name == "pi" and not args: return "np.pi"
        return f"{name}({', '.join(args)})"

    def block(self, items):
        flattened = []
        for s in items:
            if isinstance(s, list): flattened.extend(s)
            elif s is not None: flattened.append(s)
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
            if isinstance(clause, list) and len(clause) > 0:
                header = clause[0]
                if header.startswith("elif _sw_tmp"):
                    val = header.split("==")[1].split(":")[0].strip()
                    if first:
                        lines.append(f"if {var_name} == {val}:")
                        first = False
                    else:
                        lines.append(f"elif {var_name} == {val}:")
                    lines.extend(clause[1:])
                elif header == "else:":
                    if first:
                        lines.append("if True:")
                        first = False
                    else:
                        lines.append("else:")
                    lines.extend(clause[1:])
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
        catch_idx = -1
        for i, item in enumerate(items):
            if str(item) == "catch":
                catch_idx = i
                break
        
        if catch_idx + 1 < len(items) and str(items[catch_idx+1]) != "end" and not isinstance(items[catch_idx+1], list):
            err_var = items[catch_idx+1]
            catch_block = items[catch_idx+2]
            lines.append(f"except Exception as {err_var}:")
        else:
            catch_block = items[catch_idx+1]
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

    def single_ret(self, items): return str(items[0])
    def multi_ret(self, items): return [str(i) for i in items if str(i) not in ["[", "]", ","]]
    def arg_list(self, items): return [str(i) for i in items if str(i) != ","]

    def function_def(self, items):
        try:
            open_idx = items.index("(")
            close_idx = items.index(")")
            name = items[open_idx-1]
            rets = items[open_idx-3] if open_idx >= 3 and str(items[open_idx-2]) == "=" else None
            args = items[open_idx+1] if close_idx > open_idx + 1 else None
            block = items[close_idx+1]
        except Exception as e:
            return [f"# Error parsing function: {e}"]

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
