"""
Shared session state for C64 Cloud Server handlers
"""
from typing import Dict, Any

# Per-session state: session_id (int) -> state dict
_session_states: Dict[int, Dict[str, Any]] = {}


def get_session_state(session_id: int) -> Dict[str, Any]:
    """
    Get state for a given session ID, creating it if it doesn't exist.
    """
    if session_id not in _session_states:
        _session_states[session_id] = {
            'active_module': None,
            'active_dir': None,
            'active_id': None,
            'zip_id': None,
            'zip_files': None,
        }
    return _session_states[session_id]
