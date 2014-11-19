'''
Created on Nov 15, 2014

@author: wolfie
'''
import unittest
from calculator import *

class CalculatorTest(unittest.TestCase):

    def test_calculator_add_method_returns_correct_result(self):
        calc = Calculator()
        calc.current = 0
        print(calc.current)
        result = calc.add(2,2)
        self.assertEqual(4, result)
        print(result)

if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()
    