"""
Unit tests for request handlers
"""
import pytest
from dotenv import load_dotenv
from base_handler import BaseHandler
from help_handler import HelpHandler
from python_eval_handler import PythonEvalHandler
from csdb_handler import CSDBHandler
from chat_handler import ChatHandler
# from generate_pet_asc_table import Petscii

# Load environment variables for testing (override=True to prevent system vars from interfering)
load_dotenv(override=True)


class TestBaseHandler:
    """Test BaseHandler utility methods"""

    def test_petscii_to_utf8(self):
        """Test PETSCII to UTF-8 conversion"""
        # "hello" in PETSCII
        petscii_bytes = bytes([0x48, 0x45, 0x4C, 0x4C, 0x4F])
        utf8_str = BaseHandler.petscii_to_utf8(petscii_bytes)
        assert utf8_str == "hello"

    def test_utf8_to_petscii(self):
        """Test UTF-8 to PETSCII conversion"""
        utf8_str = "HELLO"
        petscii_bytes = BaseHandler.utf8_to_petscii(utf8_str)
        # PETSCII "HELLO": H=$C8, E=$C5, L=$CC, L=$CC, O=$CF
        expected = bytes([0xC8, 0xC5, 0xCC, 0xCC, 0xCF])
        assert petscii_bytes == expected


class TestHelpHandler:
    """Test HelpHandler"""

    def test_can_handle_help(self):
        """Test help command detection"""
        handler = HelpHandler()
        assert handler.can_handle("help")
        assert handler.can_handle("HELP")
        assert handler.can_handle("help commands")
        assert not handler.can_handle("I: help me")
        assert not handler.can_handle("? help")

    def test_general_help(self):
        """Test general help response"""
        handler = HelpHandler()
        response = handler.handle("help")
        assert "I:" in response
        assert "help" in response
        assert "?" in response
        assert "c:" in response

    def test_help_topic(self):
        """Test specific help topic"""
        handler = HelpHandler()
        response = handler.handle("help chat")
        assert "Chat Command" in response or "I:" in response

    def test_help_unknown_topic(self):
        """Test unknown help topic"""
        handler = HelpHandler()
        response = handler.handle("help nonexistent")
        assert "topic" in response.lower() or "available" in response.lower()


class TestPythonEvalHandler:
    """Test PythonEvalHandler"""

    def test_can_handle_eval(self):
        """Test eval command detection"""
        handler = PythonEvalHandler()
        assert handler.can_handle("? 2 + 2")
        assert handler.can_handle("?2+2")
        assert not handler.can_handle("help ?")
        assert not handler.can_handle("I: what is ?")

    def test_simple_math(self):
        """Test simple mathematical expression"""
        handler = PythonEvalHandler()
        response = handler.handle("? 2 + 2")
        assert "4" in response

    def test_hex_conversion(self):
        """Test hex conversion"""
        handler = PythonEvalHandler()
        response = handler.handle("? hex(255)")
        assert "0xff" in response.lower()

    def test_binary_conversion(self):
        """Test binary conversion"""
        handler = PythonEvalHandler()
        response = handler.handle("? bin(15)")
        assert "0b1111" in response.lower()

    def test_c64_address(self):
        """Test C64 address conversion (shows hex)"""
        handler = PythonEvalHandler()
        response = handler.handle("? 49152")
        assert "49152" in response
        # Should also show hex for C64 addresses
        assert "C000" in response.upper()

    def test_math_functions(self):
        """Test math functions"""
        handler = PythonEvalHandler()
        response = handler.handle("? sqrt(16)")
        assert "4" in response

    def test_syntax_error(self):
        """Test syntax error handling"""
        handler = PythonEvalHandler()
        response = handler.handle("? 2 +")
        assert "error" in response.lower()

    def test_unsafe_function_blocked(self):
        """Test that unsafe functions are blocked"""
        handler = PythonEvalHandler()
        response = handler.handle("? open('file.txt')")
        assert "error" in response.lower() or "unknown" in response.lower()

    def test_empty_expression(self):
        """Test empty expression"""
        handler = PythonEvalHandler()
        response = handler.handle("?")
        assert "provide" in response.lower()


class TestCSDBHandler:
    """Test CSDBHandler"""

    def test_can_handle_csdb(self):
        """Test CSDB command detection"""
        handler = CSDBHandler()
        assert handler.can_handle("c: test")
        assert handler.can_handle("C: test")
        assert handler.can_handle("c:test")
        assert not handler.can_handle("help c:")
        assert not handler.can_handle("? c:")

    def test_empty_query(self):
        """Test empty CSDB query"""
        handler = CSDBHandler()
        response = handler.handle("c:")
        assert "csdb mode" in response.lower() or "query" in response.lower()

    def test_help_response(self):
        """Test CSDB help for general query"""
        handler = CSDBHandler()
        response = handler.handle("c: find hondani")
        # Should provide usage help
        assert "TBD" in response.lower() or "TBD" in response.lower()  # TODO

    def test_release_query(self):
        """Test querying a specific release"""
        handler = CSDBHandler()
        response = handler.handle("c: release 1234")
        # Should return release info or help/error message
        assert len(response) > 0
        # The response should contain either release info or help text
        assert "release" in response.lower() or "csdb" in response.lower()


class TestChatHandler:
    """Test ChatHandler"""

    def test_can_handle_chat(self):
        """Test chat command detection"""
        handler = ChatHandler()
        assert handler.can_handle("I: hello")
        assert handler.can_handle("i: hello")
        assert handler.can_handle("I:hello")
        assert not handler.can_handle("help I:")
        assert not handler.can_handle("? I:")

    def test_empty_query(self):
        """Test empty chat query"""
        handler = ChatHandler()
        response = handler.handle("I:")
        assert "chat mode" in response.lower()
        response = handler.handle("i:")
        assert "chat mode" in response.lower()

    def test_fallback_response_when_no_llm(self):
        """Test fallback when LLM not configured"""
        handler = ChatHandler()
        # If no LLM configured, should get fallback
        if not handler.llm:
            response = handler.handle("I: hello")
            assert "unavailable" in response.lower() or "configuration" in response.lower()

    def test_llm_response(self):
        """Test actual LLM response with Azure OpenAI"""
        handler = ChatHandler()
        if handler.llm:
            response = handler.handle("I: what is 2+2?")
            assert len(response) > 0
            # The response should contain something about 4 or math
            assert len(response) > 5  # Should be a meaningful response
        else:
            # If LLM not available, skip this test
            pytest.skip("Azure OpenAI not configured")


class TestRequestDispatcher:
    """Test RequestDispatcher"""

    def test_dispatch_help(self):
        """Test dispatching help request"""
        from cloud_server import RequestDispatcher

        dispatcher = RequestDispatcher()

        # "help" in PETSCII
        petscii_text = bytes([0x48, 0x45, 0x4C, 0x50, 0x00])  # help + null

        response = dispatcher.dispatch(petscii_text)

        # Should get help response
        assert len(response) > 0

        # Convert to UTF-8 to check content
        response_utf8 = BaseHandler.petscii_to_utf8(response[:-1])
        assert "command" in response_utf8.lower() or "help" in response_utf8.lower()

    def test_dispatch_python_eval(self):
        """Test dispatching Python eval request"""
        from cloud_server import RequestDispatcher

        dispatcher = RequestDispatcher()

        # "? 2 + 2" in PETSCII
        text = "? 2 + 2"
        petscii_text = BaseHandler.utf8_to_petscii(text) + bytes([0x00])

        response = dispatcher.dispatch(petscii_text)

        # Should get result
        assert len(response) > 0
        response_utf8 = BaseHandler.petscii_to_utf8(response[:-1])
        assert "4" in response_utf8

    def test_dispatch_chat(self):
        """Test dispatching chat request"""
        from cloud_server import RequestDispatcher

        dispatcher = RequestDispatcher()

        # "I: hello" in PETSCII
        text = "I: hello"
        petscii_text = BaseHandler.utf8_to_petscii(text) + bytes([0x00])

        response = dispatcher.dispatch(petscii_text)

        # Should get some response
        assert len(response) > 0

    def test_dispatch_csdb(self):
        """Test dispatching CSDB request"""
        from cloud_server import RequestDispatcher

        dispatcher = RequestDispatcher()

        # "c: test" in PETSCII
        text = "c: test"
        petscii_text = BaseHandler.utf8_to_petscii(text) + bytes([0x00])

        response = dispatcher.dispatch(petscii_text)

        # Should get response (probably help)
        assert len(response) > 0

    def test_dispatch_unknown(self):
        """Test dispatching unknown command"""
        from cloud_server import RequestDispatcher

        dispatcher = RequestDispatcher()

        # "unknown command" in PETSCII
        text = "unknown command"
        petscii_text = BaseHandler.utf8_to_petscii(text) + bytes([0x00])

        response = dispatcher.dispatch(petscii_text)

        # Should get error message
        assert len(response) > 0
        response_utf8 = BaseHandler.petscii_to_utf8(response[:-1])
        assert "unknown" in response_utf8.lower() or "help" in response_utf8.lower()

    def test_dispatch_empty(self):
        """Test dispatching empty input"""
        from cloud_server import RequestDispatcher

        dispatcher = RequestDispatcher()

        # Just null terminator
        petscii_text = bytes([0x00])

        response = dispatcher.dispatch(petscii_text)

        # Should get empty or minimal response
        assert len(response) > 0


if __name__ == '__main__':
    pytest.main([__file__, '-v'])
