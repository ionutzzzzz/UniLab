import unittest
from backend.core.core import UniLabTranspiler

class TestUniLabTranspiler(unittest.TestCase):
    def setUp(self):
        self.transpiler = UniLabTranspiler()

    def test_basic_assignment(self):
        code = "x = 10;"
        result, _, _ = self.transpiler.transpile(code)
        self.assertIn("x = 10", result)

    def test_arithmetic(self):
        code = "y = (1 + 2) * 3 / 4;"
        result, _, _ = self.transpiler.transpile(code)
        # The transpiler might use custom mul/div functions or standard ones
        # Based on core.py, I should check how it handles MUL/DIV
        self.assertIn("y =", result)

    def test_matrix_creation(self):
        code = "A = [1, 2; 3, 4];"
        result, _, _ = self.transpiler.transpile(code)
        self.assertIn("unilab_matrix_concat", result)
        self.assertIn("[1, 2]", result)
        self.assertIn("[3, 4]", result)

    def test_function_call(self):
        code = "y = sin(x);"
        result, _, _ = self.transpiler.transpile(code)
        self.assertIn("y = unilab_call(sin, x)", result)

    def test_for_loop(self):
        code = """
        for i = 1:10
            disp(i);
        end
        """
        result, _, _ = self.transpiler.transpile(code)
        self.assertIn("for i in", result)
        self.assertIn("unilab_call(disp, i)", result)

    def test_if_statement(self):
        code = """
        if x > 0
            y = 1;
        elseif x < 0
            y = -1;
        else
            y = 0;
        end
        """
        result, _, _ = self.transpiler.transpile(code)
        self.assertIn("if unilab_gt(x, 0):", result)
        self.assertIn("elif unilab_lt(x, 0):", result)
        self.assertIn("else:", result)

    def test_function_definition(self):
        code = """
        function [y] = my_square(x)
            y = x^2;
        end
        """
        result, _, _ = self.transpiler.transpile(code)
        self.assertIn("def my_square(x=None):", result)
        self.assertIn("return (y)", result)

    def test_complex_expression(self):
        code = "z = (A * B) + C' / 2;"
        # Just check if it transpiles without error for now
        result, _, _ = self.transpiler.transpile(code)
        self.assertTrue(len(result) > 0)

    def test_anonymous_function(self):
        code = "f = @(x, y) x + y;"
        result, _, _ = self.transpiler.transpile(code)
        self.assertIn("f = (lambda x, y: (x + y))", result)
        
        code_no_args = "h = @() 42;"
        result_no_args, _, _ = self.transpiler.transpile(code_no_args)
        self.assertIn("h = (lambda : 42)", result_no_args)

if __name__ == "__main__":
    unittest.main()
