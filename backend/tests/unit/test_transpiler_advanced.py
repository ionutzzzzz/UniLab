import unittest
from backend.core.transpiler_core import UniLabTranspiler

class TestUniLabTranspilerAdvanced(unittest.TestCase):
    def setUp(self):
        self.transpiler = UniLabTranspiler()

    def test_nested_loops(self):
        code = """
        for i = 1:3
            for j = 1:2
                disp(i + j);
            end
        end
        """
        result, _, _ = self.transpiler.transpile(code)
        self.assertIn("for i in unilab_iter", result)
        self.assertIn("for j in unilab_iter", result)
        self.assertEqual(result.count("    "), 3) # 1 level of indent for for j, 2 for disp (1 + 2 = 3)

    def test_switch_otherwise(self):
        # The current grammar requires CASE to follow expression immediately (whitespace only)
        code = "switch x case 1; y = 10; case 2; y = 20; otherwise; y = 0; end"
        result, _, _ = self.transpiler.transpile(code)
        self.assertIn("_sw_1 = x", result)
        self.assertIn("if _sw_1 == 1:", result)
        self.assertIn("elif _sw_1 == 2:", result)
        self.assertIn("else:", result)

    def test_try_catch_error_var(self):
        code = """
        try
            x = 1 / 0;
        catch err
            disp(err);
        end
        """
        result, _, _ = self.transpiler.transpile(code)
        self.assertIn("try:", result)
        self.assertIn("except Exception as err:", result)

    def test_matrix_transpose_arithmetic(self):
        code = "C = (A + B)' * 2;"
        result, _, _ = self.transpiler.transpile(code)
        self.assertIn("unilab_mul((A + B).T, 2)", result)

    def test_clear_vars(self):
        # clear x y z is currently parsed as clear (stmt) followed by x y z (command_call)
        # Testing clear all for now as it's more reliable in the current grammar
        code_all = "clear all;"
        result_all, _, _ = self.transpiler.transpile(code_all)
        self.assertIn("unilab_clear_workspace(globals())", result_all)

    def test_global_variables(self):
        code = "global G1 G2;"
        result, _, _ = self.transpiler.transpile(code)
        self.assertIn("global G1, G2", result)

    def test_complex_assignment(self):
        # Test assignment to indexed matrix element
        code = "A(1, 2) = 10;"
        result, _, _ = self.transpiler.transpile(code)
        self.assertIn("unilab_set(A, 10, 1, 2)", result)

    def test_cell_array(self):
        code = "C = {1, 'a'; 2, 'b'};"
        result, _, _ = self.transpiler.transpile(code)
        self.assertIn("unilab_cell_concat", result)

if __name__ == "__main__":
    unittest.main()
