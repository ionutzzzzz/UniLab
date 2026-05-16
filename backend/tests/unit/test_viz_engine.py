import unittest
import numpy as np
from backend.core.runtime import unilab_ascii_plot, unilab_ascii_heatmap, isempty
from backend.core.core import UniLabTranspiler

class TestVizEngine(unittest.TestCase):
    def test_ascii_plot_basic(self):
        y = [1, 2, 3]
        x = [0, 1, 2]
        result = unilab_ascii_plot(y, x, height=5, width=10)
        self.assertIsInstance(result, str)
        self.assertIn("*", result)
        self.assertIn("3.00", result)
        self.assertIn("1.00", result)

    def test_ascii_plot_types(self):
        y = [1, 0, 1]
        x = [1, 2, 3]
        
        # Scatter
        res_scatter = unilab_ascii_plot(y, x, height=5, width=10, plot_type='scatter')
        self.assertIn("o", res_scatter)
        
        # Bar
        res_bar = unilab_ascii_plot(y, x, height=5, width=10, plot_type='bar')
        self.assertIn("#", res_bar)
        
        # Stem
        res_stem = unilab_ascii_plot(y, x, height=5, width=10, plot_type='stem')
        self.assertIn("o", res_stem)
        self.assertIn("|", res_stem)
        
        # Stairs
        res_stairs = unilab_ascii_plot(y, x, height=5, width=10, plot_type='stairs')
        self.assertIn("*", res_stairs)

    def test_ascii_heatmap(self):
        M = [[1, 2], [3, 4]]
        result = unilab_ascii_heatmap(M, height=2, width=2)
        self.assertIn("+--+", result)
        self.assertIn("|", result)

    def test_isempty(self):
        self.assertTrue(isempty([]))
        self.assertTrue(isempty(np.array([])))
        self.assertTrue(isempty(None))
        self.assertFalse(isempty([1]))
        self.assertFalse(isempty(np.array([1])))

class TestTranspilerImprovements(unittest.TestCase):
    def setUp(self):
        self.transpiler = UniLabTranspiler()

    def test_empty_matrix_transpilation(self):
        code = "A = []; B = {};"
        result, _, _ = self.transpiler.transpile(code)
        self.assertIn("A = unilab_matrix_concat()", result)
        self.assertIn("B = unilab_cell_concat()", result)

    def test_optional_arguments_transpilation(self):
        code = "function [y] = test_func(a, b, c)\n y = a;\n end"
        result, _, _ = self.transpiler.transpile(code)
        self.assertIn("def test_func(a=None, b=None, c=None):", result)
        self.assertIn("nargin = unilab_nargin_sum(1 for x in [a, b, c] if x is not None)", result)

    def test_string_concatenation(self):
        # We need to test the runtime behavior of the transpiled code
        from backend.core.runtime import unilab_matrix_concat
        res = unilab_matrix_concat("Hello", " ", "World")
        self.assertEqual(res, "Hello World")
        
        # Test how it's called from transpiled code (single list)
        res_wrapped = unilab_matrix_concat(["Hello", " ", "World"])
        self.assertEqual(res_wrapped, "Hello World")

if __name__ == "__main__":
    unittest.main()
