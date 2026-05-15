from lark import Lark, Transformer, v_args

g = r"""
start: assignment
assignment: CNAME "=" NUMBER ";"?
%import common.CNAME
%import common.NUMBER
%import common.WS
%ignore WS
"""

@v_args(inline=True)
class T(Transformer):
    def assignment(self, *args):
        print(f"ARGS: {args}")
        return "ok"

p = Lark(g, parser='earley')
p.parse("val = 123;").data # Wait, I need to transform
T().transform(p.parse("val = 123;"))
T().transform(p.parse("val = 123"))
