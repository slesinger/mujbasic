"""
PythonEvalHandler - Evaluates Python expressions

Provides safe Python expression evaluation for C64 users.
Processes requests starting with "?"
"""
import logging
import math
from typing import Any
from base_handler import BaseHandler

logger = logging.getLogger(__name__)

# Safe built-in functions allowed during eval
SAFE_BUILTINS = {
    'abs': abs,
    'bin': bin,
    'bool': bool,
    'chr': chr,
    'divmod': divmod,
    'float': float,
    'hex': hex,
    'int': int,
    'len': len,
    'max': max,
    'min': min,
    'oct': oct,
    'ord': ord,
    'pow': pow,
    'round': round,
    'str': str,
    'sum': sum,
}

# Safe math functions
SAFE_MATH = {
    'pi': math.pi,
    'e': math.e,
    'sqrt': math.sqrt,
    'sin': math.sin,
    'cos': math.cos,
    'tan': math.tan,
    'floor': math.floor,
    'ceil': math.ceil,
    'log': math.log,
    'log10': math.log10,
    'exp': math.exp,
}


class PythonEvalHandler(BaseHandler):
    """Handler for Python expression evaluation"""

    def __init__(self):
        """Initialize PythonEvalHandler"""
        # Create safe namespace
        self.safe_namespace = {}
        self.safe_namespace.update(SAFE_BUILTINS)
        self.safe_namespace.update(SAFE_MATH)

    def can_handle(self, text: str, session_id: int = 0) -> bool:
        """
        Check if text starts with "?"

        Args:
            text: UTF-8 text to check

        Returns:
            True if text starts with "?"
        """
        return text.strip().startswith("?")

    def handle(self, text: str, session_id: int = 0) -> str:
        """
        Evaluate Python expression and return result

        Args:
            text: UTF-8 text (should start with "?")

        Returns:
            UTF-8 response text with evaluation result
        """
        # Remove "?" prefix
        expression = text.strip()[1:].strip()

        if not expression:
            return "Please provide an expression to evaluate after '?'"

        logger.info(f"Evaluating: {expression}")

        try:
            # Evaluate expression in safe namespace
            result = eval(expression, {"__builtins__": {}}, self.safe_namespace)

            # Format result
            result_str = self._format_result(result)

            logger.info(f"Result: {result_str}")
            return result_str

        except SyntaxError as e:
            logger.warning(f"Syntax error: {e}")
            return f"Syntax error: {e.msg}"

        except NameError as e:
            logger.warning(f"Name error: {e}")
            return f"Unknown name: {str(e)}"

        except Exception as e:
            logger.error(f"Evaluation error: {e}")
            return f"Error: {str(e)}"

    def _format_result(self, result: Any) -> str:
        """
        Format evaluation result for display

        Args:
            result: Evaluation result

        Returns:
            Formatted string
        """
        # Handle different types appropriately
        if isinstance(result, bool):
            return str(result)
        elif isinstance(result, int):
            # For C64 users, also show hex for interesting values
            if result >= 0 and result <= 65535:
                return f"{result} (${result:04X})"
            return str(result)
        elif isinstance(result, float):
            return f"{result:.6f}".rstrip('0').rstrip('.')
        elif isinstance(result, str):
            return f'"{result}"'
        else:
            return str(result)
