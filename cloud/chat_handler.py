"""
ChatHandler - Handles general chat requests to LLM Agent

Uses LangChain with Context7 MCP server for documentation access.
Processes requests starting with "I:"
"""
import os
import logging
from base_handler import BaseHandler
from dotenv import load_dotenv
from shared_state import get_session_state

# Load environment variables (override=True to prevent system vars from interfering)
load_dotenv(override=True)

logger = logging.getLogger(__name__)

# System prompt for chat agent
CHAT_SYSTEM_PROMPT = """You are a helpful AI assistant for C64 computer users.
You are communicating with a Commodore 64 computer from the 1980s, so keep your responses concise and suitable for a small screen (40 columns x 25 lines).
Focus on practical, actionable advice.
When discussing code or technical topics, consider the C64's 8-bit architecture, 64KB RAM limit, and BASIC/assembly language environment.
Be friendly but brief."""


class ChatHandler(BaseHandler):
    """Handler for general chat requests using LLM"""

    def __init__(self):
        """Initialize ChatHandler with LangChain components"""
        self.llm = None
        self.tools = []
        self._initialize_llm()
        self._initialize_tools()

    def _initialize_llm(self):
        """Initialize LangChain LLM with Azure OpenAI"""
        try:
            # Check for Azure OpenAI credentials
            azure_key = os.getenv('AZURE_OPENAI_API_KEY')
            azure_endpoint = os.getenv('AZURE_OPENAI_ENDPOINT')
            azure_deployment = os.getenv('AZURE_OPENAI_DEPLOYMENT_NAME')
            azure_version = os.getenv('AZURE_OPENAI_API_VERSION', '2024-02-15-preview')
            
            if not azure_key or not azure_endpoint or not azure_deployment:
                logger.warning("Azure OpenAI credentials not set, ChatHandler will use basic responses")
                return

            # Import LangChain components
            try:
                from langchain_openai import AzureChatOpenAI

                # Initialize LLM (using Azure OpenAI)
                self.llm = AzureChatOpenAI(
                    azure_deployment=azure_deployment,
                    api_version=azure_version,
                    azure_endpoint=azure_endpoint,
                    api_key=azure_key,
                    temperature=0.7
                )
                logger.info(f"ChatHandler initialized with Azure OpenAI (deployment: {azure_deployment})")

            except ImportError as e:
                logger.warning(f"LangChain not installed: {e}")
                logger.info("Install with: pip install langchain langchain-openai")

        except Exception as e:
            logger.error(f"Error initializing LLM: {e}")

    def _initialize_tools(self):
        """Initialize LangChain tools including web search"""
        try:
            # Check for Google API key for web search
            google_api_key = os.getenv('GOOGLE_API_KEY')
            google_cse_id = os.getenv('GOOGLE_CSE_ID')

            if google_api_key and google_cse_id:
                try:
                    from langchain_google_community import GoogleSearchAPIWrapper
                    from langchain_core.tools import Tool

                    search = GoogleSearchAPIWrapper(
                        google_api_key=google_api_key,
                        google_cse_id=google_cse_id
                    )

                    search_tool = Tool(
                        name="web_search",
                        description="Search the web for current information. Use this when you need up-to-date information or facts.",
                        func=search.run
                    )

                    self.tools.append(search_tool)
                    logger.info("Google search tool initialized")

                except ImportError as e:
                    logger.warning(f"Google search tools not available: {e}")
            else:
                logger.info("GOOGLE_API_KEY or GOOGLE_CSE_ID not set, web search disabled")

        except Exception as e:
            logger.error(f"Error initializing tools: {e}")

    def can_handle(self, text: str, session_id: int = 0) -> bool:
        """
        Check if text starts with "I:" or if chat is the active module.

        Args:
            text: UTF-8 text to check
            session_id: The session ID for the request

        Returns:
            True if this handler can process the text
        """
        t = text.strip().lower()
        state = get_session_state(session_id)
        if t.startswith("i:"):
            return True
        if state.get('active_module') == 'i':
            if any(t.startswith(p) for p in ["c:", "?", "help"]):
                return False
            return True
        return False

    def handle(self, text: str, session_id: int = 0) -> str:
        """
        Process chat request using LLM

        Args:
            text: UTF-8 text (should start with "I:")
            session_id: The session ID for the request

        Returns:
            UTF-8 response text
        """
        t = text.strip()
        t_lower = t.lower()
        state = get_session_state(session_id)

        if t_lower.startswith("i:"):
            query = t[2:].strip()
            if not query:
                state['active_module'] = 'i'
                return "Chat mode. I'm listening."
        elif state.get('active_module') == 'i':
            query = t
        else:
            # This should not be reached if can_handle is correct
            return self._fallback_response("Internal error: handle called unexpectedly.")

        if not query:
            return "Please provide a question or statement."

        logger.info(f"Chat query: {query}")

        # If LLM is not initialized, provide fallback response
        if not self.llm:
            return self._fallback_response(query)

        try:
            # Use LLM to generate response
            response = self._query_llm(query)
            return response

        except Exception as e:
            logger.error(f"Error processing chat request: {e}")
            return f"Error: {str(e)}"

    def _fallback_response(self, query: str) -> str:
        """
        Provide fallback response when LLM is not available

        Args:
            query: User query

        Returns:
            Simple response
        """
        return "Chat service is currently unavailable. Please check API configuration."

    def _query_llm(self, query: str) -> str:
        """
        Query LLM with the user's request

        Args:
            query: User query

        Returns:
            LLM response
        """
        try:
            from langchain_core.messages import HumanMessage, SystemMessage

            messages = [
                SystemMessage(content=CHAT_SYSTEM_PROMPT),
                HumanMessage(content=query)
            ]

            response = self.llm.invoke(messages)
            return response.content

        except Exception as e:
            logger.error(f"Error querying LLM: {e}")
            return "I encountered an error processing your request."
