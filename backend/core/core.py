from lark import Lark, Transformer, v_args

# EBNF Grammar for a subset of MATLAB with correct precedence
MATLAB_GRAMMAR = r"""
    ?start: statement*

    ?statement: assignment
              | command
              | expression ";"? -> expr_stmt

    assignment: CNAME "=" expression ";"?

    command: CNAME CNAME+ ";"?

    ?expression: range_expr
    
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

    ?power: atom
          | power "^" atom           -> pow
          | power ".^" atom          -> dot_pow

    ?atom: NUMBER                    -> number
         | STRING                    -> string
         | CNAME                     -> var
         | "(" expression ")"
         | matrix
         | function_call

    matrix: "[" row (";" row)* "]"
    row: expression (","? expression)*

    function_call: CNAME "(" [expression ("," expression)*] ")"

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

    def number(self, n):
        return n[0]

    def string(self, s):
        # Convert MATLAB string to Python string
        # MATLAB '' -> ' in string
        content = str(s[0])[1:-1].replace("''", "'")
        return f"'{content}'"

    def var(self, v):
        name = str(v[0])
        if name == "pi":
            return "np.pi"
        self.variables.add(name)
        return name

    def assignment(self, items):
        name, value = items
        self.variables.add(str(name))
        return f"{name} = {value}"

    def command(self, items):
        name = str(items[0])
        args = [f"'{str(arg)}'" for arg in items[1:] if arg is not None]
        return f"{name}({', '.join(args)})"

    def expr_stmt(self, items):
        return items[0]

    def add(self, items):
        return f"({items[0]} + {items[1]})"

    def sub(self, items):
        return f"({items[0]} - {items[1]})"

    def mul(self, items):
        return f"unilab_mul({items[0]}, {items[1]})"

    def div(self, items):
        return f"unilab_div({items[0]}, {items[1]})"

    def dot_mul(self, items):
        return f"({items[0]} * {items[1]})"

    def dot_div(self, items):
        return f"({items[0]} / {items[1]})"

    def pow(self, items):
        return f"unilab_pow({items[0]}, {items[1]})"

    def dot_pow(self, items):
        return f"({items[0]} ** {items[1]})"

    def neg(self, items):
        return f"-{items[0]}"

    def matrix(self, rows):
        row_strs = []
        for row in rows:
            if row is not None:
                # row is a list from row()
                items = [str(i) for i in row if i is not None]
                row_strs.append(f"[{', '.join(items)}]")
        return f"np.array([{', '.join(row_strs)}])"

    def row(self, items):
        return [i for i in items if i is not None]

    def range2(self, items):
        start, end = items
        return f"np.arange({start}, {end} + 1)"

    def range3(self, items):
        start, step, end = items
        return f"np.arange({start}, {end} + {step}, {step})"

    def function_call(self, items):
        name = str(items[0])
        args = [str(i) for i in items[1:] if i is not None]
        if name == "pi" and not args:
            return "np.pi"
        return f"{name}({', '.join(args)})"

    def start(self, statements):
        # print(f"DEBUG: statements={statements}")
        filtered = [s for s in statements if s is not None]
        return "\n".join(filtered)

def transpile(matlab_code):
    parser = Lark(MATLAB_GRAMMAR, parser='lalr', transformer=MatlabToPython())
    python_code = parser.parse(matlab_code)
    return python_code


if __name__ == "__main__":
    test_code = """
    x = 0:0.1:2*pi;
    y = sin(x);
    A = [1 2; 3 4];
    B = A * A;
    C = A .* A;
    """
    print(transpile(test_code))
