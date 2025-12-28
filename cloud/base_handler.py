"""
Base handler class for request processing
"""
from abc import ABC, abstractmethod
from generate_pet_asc_table import Petscii


class BaseHandler(ABC):
    """Base class for all request handlers"""

    @abstractmethod
    def can_handle(self, text: str, session_id: int = 0) -> bool:
        """
        Check if this handler can process the given text

        Args:
            text: UTF-8 text to check
            session_id: The session ID for the request

        Returns:
            True if this handler can process the text
        """
        pass

    @abstractmethod
    def handle(self, text: str, session_id: int = 0) -> str:
        """
        Process the request and return response

        Args:
            text: UTF-8 text to process
            session_id: The session ID for the request

        Returns:
            UTF-8 response text
        """
        pass

    @staticmethod
    def petscii_to_utf8(petscii_bytes: bytes) -> str:
        """
        Convert PETSCII bytes to UTF-8 string

        Args:
            petscii_bytes: PETSCII encoded bytes

        Returns:
            UTF-8 string
        """
        ascii_bytes = bytes([Petscii.petscii2ascii(b) for b in petscii_bytes])
        return ascii_bytes.decode('ascii', errors='replace')

    @staticmethod
    def utf8_to_petscii(text: str) -> bytes:
        """
        Convert UTF-8 string to PETSCII bytes

        Args:
            text: UTF-8 string

        Returns:
            PETSCII encoded bytes
        """
        return bytes([Petscii.ascii2petscii(ord(c)) for c in text])
