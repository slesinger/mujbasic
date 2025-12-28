"""
HelpHandler - Handles help requests

Provides static help text or uses LLM to find relevant help topics.
Processes requests starting with "help"
"""
import os
import logging
from base_handler import BaseHandler
from dotenv import load_dotenv

# Load environment variables (override=True to prevent system vars from interfering)
load_dotenv(override=True)

logger = logging.getLogger(__name__)

# System prompt for help search
HELP_SYSTEM_PROMPT = """You are a help system for a C64 Cloud Server.
Analyze the user's help query and provide the most relevant help information.
Keep responses concise and suitable for a C64 screen (40 columns).
Focus on available commands and their usage."""

# Static help text
HELP_TEXT = """C64 Cloud Server Commands:

I: <query>    - Chat with AI assistant
help [topic]  - Show this help or search topics
? <expr>      - Evaluate Python expression
c: <query>    - Search CSDB.dk database

Examples:
I: what is the c64?
help chat
? 2 + 2
c: latest releases

For detailed help on a topic, use:
help <topic>
"""

# Help topics dictionary
HELP_TOPICS = {
    "chat": """Chat Command (I:)

Send questions or statements to an AI assistant.

Usage: I: <your message>

Examples:
  I: explain machine code
  I: how do I save a file?
  I: what is peek and poke?

The AI understands C64 context and will provide relevant answers.""",

    "python": """Python Eval Command (?)

Evaluate Python expressions and get results.

Usage: ? <expression>

Examples:
  ? 2 + 2
  ? 255 * 256
  ? hex(49152)
  ? bin(15)

Security: Only basic math and functions are allowed for safety.""",

    "csdb": """CSDB Command (c:)

Search the csdb.dk database for C64 releases, groups, and sceners.

Usage: c: <search query>

Examples:
  c: latest releases
  c: fairlight demos
  c: rob hubbard music

Returns information from the comprehensive C64 Scene Database.""",

    "commands": HELP_TEXT,
}


class HelpHandler(BaseHandler):
    """Handler for help requests"""

    def __init__(self):
        """Initialize HelpHandler with optional LLM support"""
        self.llm = None
        self._initialize_llm()

    def _initialize_llm(self):
        """Initialize LLM for help topic search"""
        try:
            azure_key = os.getenv('AZURE_OPENAI_API_KEY')
            azure_endpoint = os.getenv('AZURE_OPENAI_ENDPOINT')
            azure_deployment = os.getenv('AZURE_OPENAI_DEPLOYMENT_NAME')
            azure_version = os.getenv('AZURE_OPENAI_API_VERSION', '2024-02-15-preview')

            if azure_key and azure_endpoint and azure_deployment:
                try:
                    from langchain_openai import AzureChatOpenAI

                    self.llm = AzureChatOpenAI(
                        azure_deployment=azure_deployment,
                        api_version=azure_version,
                        azure_endpoint=azure_endpoint,
                        api_key=azure_key,
                        temperature=0.3
                    )
                    logger.info("HelpHandler initialized with LLM support")
                except ImportError:
                    logger.info("LangChain not available for help search")
        except Exception as e:
            logger.error(f"Error initializing help LLM: {e}")

    def can_handle(self, text: str, session_id: int = 0) -> bool:
        """
        Check if text starts with "help"

        Args:
            text: UTF-8 text to check

        Returns:
            True if text starts with "help" (case-insensitive)
        """
        return text.strip().lower().startswith("help")

    def handle(self, text: str, session_id: int = 0) -> str:
        """
        Process help request

        Args:
            text: UTF-8 text (should start with "help")

        Returns:
            UTF-8 response text
        """
        # Remove "help" prefix and get topic
        parts = text.strip().split(maxsplit=1)
        topic = parts[1].strip().lower() if len(parts) > 1 else None

        if not topic:
            # Return general help
            return HELP_TEXT

        # Check if topic exists in static help
        if topic in HELP_TOPICS:
            return HELP_TOPICS[topic]

        # Try LLM-based help search if available
        if self.llm:
            return self._search_help_with_llm(topic)

        # Fallback: suggest available topics
        available = ", ".join(sorted(HELP_TOPICS.keys()))
        return f"Unknown topic: {topic}\n\nAvailable topics: {available}"

    def _search_help_with_llm(self, topic: str) -> str:
        """
        Use LLM to find relevant help for the topic

        Args:
            topic: Help topic to search for

        Returns:
            Help text
        """
        try:
            from langchain_core.messages import HumanMessage, SystemMessage

            # Create prompt to search help topics
            topics_text = "\n\n".join([
                f"Topic: {name}\n{content}"
                for name, content in HELP_TOPICS.items()
            ])

            query = f"""User is asking for help about: {topic}

Available help topics:
{topics_text}

Find the most relevant help topic and return its content. If no exact match, provide a brief explanation of what '{topic}' might relate to in the context of this C64 cloud server."""  # noqa

            messages = [
                SystemMessage(content=HELP_SYSTEM_PROMPT),
                HumanMessage(content=query)
            ]

            response = self.llm.invoke(messages)
            return response.content

        except Exception as e:
            logger.error(f"Error searching help with LLM: {e}")
            available = ", ".join(sorted(HELP_TOPICS.keys()))
            return f"Error searching help.\n\nAvailable topics: {available}"
