"""
CSDBHandler - Handles requests to csdb.dk database

Queries the CSDB.dk API for C64 scene information.
Processes requests starting with "c:"
"""

import logging
import os
import requests
import xml.etree.ElementTree as ET
from typing import Optional, List
from pydantic import BaseModel
from base_handler import BaseHandler
from dotenv import load_dotenv


class CSDBRelease(BaseModel):
    name: str
    release_type: str
    release_date: str
    groups: List[str]


class CSDBGroup(BaseModel):
    name: str
    member_count: int
    release_count: int


class CSDBScener(BaseModel):
    handle: str
    real_name: Optional[str] = None
    groups: List[str]


class CSDBEvent(BaseModel):
    name: str
    start_date: str
    end_date: Optional[str] = None

# Load environment variables (override=True to prevent system vars from interfering)


load_dotenv(override=True)

logger = logging.getLogger(__name__)

# CSDB API base URL
CSDB_API_URL = "https://csdb.dk/webservice/"


class CSDBHandler(BaseHandler):
    """Handler for CSDB.dk database queries"""

    # Per-session state: session_id (int) -> state dict
    _session_states = {}

    @classmethod
    def get_session_state(cls, session_id: int):
        if session_id not in cls._session_states:
            cls._session_states[session_id] = {
                'active_module': None,   # e.g. 'c'
                'active_dir': None,      # e.g. 'group', 'release', etc.
                'active_id': None,       # e.g. 901 (if in detail)
                'last_find': None,       # last find result dict
                # type of last find (e.g. 'group', 'release', etc.)
                'last_find_type': None,
            }
        return cls._session_states[session_id]

    def __init__(self):
        """Initialize CSDBHandler"""
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'C64-Cloud-Server/1.0'
        })

        # Add authentication if available
        csdb_user = os.getenv('CSDB_USER')
        csdb_password = os.getenv('CSDB_PASSWORD')
        if csdb_user and csdb_password:
            self.session.auth = (csdb_user, csdb_password)
            logger.info(
                f"CSDB authentication configured for user: {csdb_user}")

    def can_handle(self, text: str, session_id: int = 0) -> bool:
        """
        Only handle if text starts with c:, or if c: is the active module for this session.
        """
        t = text.strip().lower()
        state = self.get_session_state(session_id)
        if t.startswith("c:"):
            return True
        # Only assume csdb module if user explicitly switched to it
        if state['active_module'] == 'c':
            # If user enters a known other module prefix, don't handle
            for prefix in ["i:", "help", "?", "h:"]:
                if t.startswith(prefix):
                    return False
            return True
        return False

    def handle(self, text: str, session_id: int = 0) -> str:
        """
        Process CSDB query or virtual navigation (cd/find/etc) for a session
        """
        t = text.strip()
        t_lower = t.lower()
        state = self.get_session_state(session_id)

        # If starts with c:, reset module and parse rest
        if t_lower.startswith("c:"):
            state['active_module'] = 'c'
            state['active_dir'] = None
            state['active_id'] = None
            state['last_find'] = None
            state['last_find_type'] = None
            query = t[2:].strip()
            if not query:
                return "CSDB module active"
            # If user enters e.g. c: group 123, c: find foo, etc, process as normal
            return self._process_csdb_command(query, session_id)

        # If c: is active module, interpret commands
        if state['active_module'] == 'c':
            # pwd command
            if t_lower == 'pwd':
                path = 'c:/'
                if state['active_dir']:
                    path += state['active_dir'] + '/'
                    if state['active_id']:
                        path += str(state['active_id'])
                return path
            # cd command
            if t_lower.startswith("cd "):
                arg = t[3:].strip()
                # Support 'cd <type>/<id>' syntax
                import re
                m = re.match(r"(group|release|scener|event|bbs|sid)[/\\](\d+)$", arg, re.IGNORECASE)
                if m:
                    cd_type = m.group(1).lower()
                    cd_id = m.group(2)
                    state['active_dir'] = cd_type
                    state['active_id'] = int(cd_id)
                    return self._get_entry_info(cd_type, int(cd_id))
                # cd / (go to root)
                if arg == "/":
                    state['active_dir'] = None
                    state['active_id'] = None
                    return "Changed to root."
                # cd .. (go up one level)
                if arg == "..":
                    if state['active_id'] is not None:
                        state['active_id'] = None
                        return f"Moved up to {state['active_dir']}/"
                    elif state['active_dir'] is not None:
                        state['active_dir'] = None
                        return "Moved up to root."
                    else:
                        return "Already at root."
                # cd <type> (e.g. group, release, scener, event, bbs, sid)
                if arg in ['group', 'release', 'scener', 'event', 'bbs', 'sid']:
                    state['active_dir'] = arg
                    state['active_id'] = None
                    return f"Changed to {arg}/"
                # cd <id> (if in a dir)
                if state['active_dir'] and arg.isdigit():
                    state['active_id'] = int(arg)
                    # e.g. cd 901 in group dir => c: group 901
                    return self._process_csdb_command(f"{state['active_dir']} {arg}", session_id)
                return "Unknown cd target. Use 'cd group', 'cd release', etc."
            # find command
            if t_lower.startswith("find "):
                search_text = t[5:].strip()
                result = self._find_csdb(search_text)
                state['last_find'] = result
                state['active_id'] = None
                if state['active_dir']:
                    filtered = {}
                    type_map = {
                        'release': ('releases', 'release_count'),
                        'group': ('groups', 'group_count'),
                        'scener': ('sceners', 'scener_count'),
                        'bbs': ('bbses', 'bbs_count'),
                        'sid': ('sids', 'sid_count'),
                    }
                    key, count_key = type_map.get(
                        state['active_dir'], (None, None))
                    if key:
                        filtered[key] = result.get(key, [])
                        filtered[count_key] = result.get(count_key, 0)
                        section = state['active_dir'] + \
                            (" matches" if state['active_dir']
                             != 'bbs' else " match")
                        show_all_label = key
                        return self._format_find_result(filtered, custom_section=(section, show_all_label, key, count_key))
                return self._format_find_result(result)
            # cd <id> without dir
            if t_lower.startswith("cd ") and t[3:].strip().isdigit():
                return "Please 'cd' into a type first (e.g. 'cd group') before 'cd <id>'"
            # If user enters e.g. group 123, release 456, etc
            parts = t.strip().split()
            if len(parts) == 2 and parts[0] in ['group', 'release', 'scener', 'event', 'bbs', 'sid'] and parts[1].isdigit():
                state['active_dir'] = parts[0]
                state['active_id'] = int(parts[1])
                return self._process_csdb_command(t, session_id)
            # If user enters just a number and in a dir, treat as cd <id>
            if t.isdigit() and state['active_dir']:
                state['active_id'] = int(t)
                return self._process_csdb_command(f"{state['active_dir']} {t}", session_id)
            # Help
            if t_lower in ['help', '?']:
                return self._search_help("")
            # Otherwise, unknown command
            return "Unknown CSDB command. Use 'find <text>', 'cd <type>', or 'cd <id>'."

        # Fallback: not handled
        return "Unknown command. Type 'help' for available commands."

    def _process_csdb_command(self, query: str, session_id: int = 0) -> str:
        """
        Parse and execute a CSDB command string (e.g. 'group 123', 'find foo', etc) for a session
        """
        try:
            result = self._query_csdb(query)
            return result
        except Exception as e:
            logger.error(f"Error querying CSDB: {e}")
            return f"Error: {str(e)}"

    def _format_find_result(self, result: dict, custom_section=None) -> str:
        """
        Format a find result dict as text (same as _find_csdb output)
        If custom_section is provided, only format that section: (section, show_all_label, key, count_key)
        """
        if 'error' in result:
            return result['error']

        def fmt_items(items, count, section, show_all_label):
            lines = []
            if count:
                lines.append(f"{count}   {section}:")
                for item in items[:5]:
                    id_str = str(item.get('id', ''))
                    txt = item.get('text', '')
                    line = f"{id_str:<6}{txt}"[:40]
                    lines.append(line)
                if count > 5:
                    lines.append(
                        f"Show all {count} matching {show_all_label}"[:40])
            return lines
        output = []
        if custom_section:
            section, show_all_label, key, count_key = custom_section
            output += fmt_items(result.get(key, []),
                                result.get(count_key, 0), section, show_all_label)
        else:
            output += fmt_items(result.get('releases', []),
                                result.get('release_count', 0), 'release matches', 'releases')
            output += fmt_items(result.get('groups', []),
                                result.get('group_count', 0), 'group match', 'groups')
            output += fmt_items(result.get('sceners', []),
                                result.get('scener_count', 0), 'scener matches', 'sceners')
            output += fmt_items(result.get('bbses', []),
                                result.get('bbs_count', 0), 'BBS match', 'BBSes')
            output += fmt_items(result.get('sids', []),
                                result.get('sid_count', 0), 'SID matches', 'SIDs')
        return '\n'.join(output) if output else "No results found."

    def _query_csdb(self, query: str) -> str:
        """
        Query CSDB API

        Args:
            query: Search query

        Returns:
            Formatted response text
        """
        parts = query.strip().split()
        if len(parts) >= 2:
            cmd = parts[0].lower()
            if cmd in ['release', 'group', 'scener', 'event', 'bbs', 'sid']:
                try:
                    entry_id = int(parts[1])
                    return self._get_entry_info(cmd, entry_id)
                except ValueError:
                    pass
            elif cmd == 'find':
                search_text = ' '.join(parts[1:])
                return self._find_csdb(search_text)
        # For general queries, provide guidance
        return self._search_help(query)

    def _find_csdb(self, search_text: str) -> dict:
        """
        Perform CSDB find (HTML search) and return parsed result dict
        """
        from csdb_search_parser import parse_csdb_find
        import requests
        url = f"https://csdb.dk/search/?seinsel=all&search={search_text}&Go.x=8&Go.y=9"
        try:
            resp = requests.get(url, timeout=10)
            result = parse_csdb_find(resp.text)
            return result
        except Exception as e:
            return {'error': f"Network error: {str(e)}"}

    def _get_entry_info(self, entry_type: str, entry_id: int, depth: int = 2) -> str:
        """
        Get information for a specific CSDB entry

        Args:
            entry_type: Type of entry (release, group, scener, event, bbs, sid)
            entry_id: CSDB ID of the entry
            depth: Recursion depth for API call (default 2, max 4)

        Returns:
            Formatted entry information
        """
        try:
            # Build API URL
            params = {
                'type': entry_type,
                'id': entry_id,
                'depth': min(depth, 4)  # Max depth is 4
            }

            logger.info(f"Fetching {entry_type} {entry_id} from CSDB")

            response = self.session.get(
                CSDB_API_URL, params=params, timeout=10)
            response.raise_for_status()

            # Parse XML response
            root = ET.fromstring(response.content)

            # Format based on entry type
            if entry_type == 'release':
                return self._format_release(root)
            elif entry_type == 'group':
                return self._format_group(root)
            elif entry_type == 'scener':
                return self._format_scener(root)
            elif entry_type == 'event':
                return self._format_event(root)
            else:
                # Generic format
                return self._format_generic(root)

        except requests.RequestException as e:
            logger.error(f"HTTP error querying CSDB: {e}")
            return f"Network error: {str(e)}"
        except ET.ParseError as e:
            logger.error(f"XML parse error: {e}")
            return "Error parsing CSDB response"
        except Exception as e:
            logger.error(f"Error getting entry info: {e}")
            return f"Error: {str(e)}"

    def _format_release(self, root: ET.Element) -> str:
        """Format release information"""
        try:
            name = root.findtext('.//Release/Name', 'Unknown')
            release_type = root.findtext('.//Release/Type', 'Unknown')
            release_date = root.findtext('.//Release/ReleaseDate', 'Unknown')
            groups = [group.findtext('Name', 'Unknown') for group in root.findall(
                './/Release/ReleasedBy/Group')]
            model = CSDBRelease(
                name=name,
                release_type=release_type,
                release_date=release_date,
                groups=groups
            )
            groups_str = ', '.join(model.groups) if model.groups else 'Unknown'
            result = f"Release: {model.name}\n"
            result += f"Type: {model.release_type}\n"
            result += f"Date: {model.release_date}\n"
            result += f"By: {groups_str}"
            return result
        except Exception as e:
            logger.error(f"Error formatting release: {e}")
            return "Error formatting release information"

    def _format_group(self, root: ET.Element) -> str:
        """Format group information"""
        try:
            name = root.findtext('.//Group/Name', 'Unknown')
            abbr = root.findtext('.//Group/Abbreviation', None)
            country = root.findtext('.//Group/BaseCountry', 'Unknown')
            user_rating = root.findtext('.//Group/UserRating', None)
            votes_needed = root.findtext('.//Group/VotesNeeded', None)
            votes_left = root.findtext('.//Group/VotesLeft', None)
            vote_url = root.findtext('.//Group/VoteURL', None)
            votestat_url = root.findtext('.//Group/VoteStatURL', None)

            # Heading
            abbr_str = f" ({abbr})" if abbr else ""
            heading = f"{name}{abbr_str}\t{country}\n\n"

            # User rating
            rating_str = "User rating: "
            if user_rating:
                rating_str += f"{user_rating} votes"
            elif votes_needed and votes_left:
                rating_str += f"awaiting {votes_needed} votes ({votes_left} left)"
            else:
                rating_str += "N/A"
            if vote_url:
                rating_str += "   vote"
            if votestat_url:
                rating_str += "   See votestatistics"

            # Members
            members = root.findall('.//Group/Members/Member')
            member_lines = []
            for m in members:
                m_name = m.findtext('Name', 'Unknown')
                m_status = m.findtext('Status', None)
                m_roles = m.findtext('Roles', None)
                status_str = f" ({m_status})" if m_status else ""
                roles_str = f"\t....\t{m_roles}" if m_roles else ""
                line = f"{m_name}{status_str}{roles_str}"[:40]
                member_lines.append(line)

            # Releases
            releases = root.findall('.//Group/Releases/Release')
            release_lines = []
            for r in releases:
                r_id = r.findtext('ID', '')
                r_name = r.findtext('Name', 'Unknown')
                r_year = r.findtext('Year', '')
                r_type = r.findtext('Type', '')
                line = f"{r_id:<6}{r_name}, {r_year}\t{r_type}"[:40]
                release_lines.append(line)

            result = heading
            result += f"{rating_str}\n\n"
            result += "All Members :\n"
            result += '\n'.join(member_lines) + '\n\n'
            result += f"Releases : ({len(release_lines)})\n"
            result += '\n'.join(release_lines)
            return result
        except Exception as e:
            logger.error(f"Error formatting group: {e}")
            return "Error formatting group information"

    def _format_scener(self, root: ET.Element) -> str:
        """Format scener information"""
        try:
            handle = root.findtext('.//Scener/Handle', 'Unknown')
            real_name = root.findtext('.//Scener/RealName', None)
            groups = [group.findtext('Name', 'Unknown')
                      for group in root.findall('.//Scener/Groups/Group')]
            model = CSDBScener(
                handle=handle,
                real_name=real_name,
                groups=groups
            )
            result = f"Handle: {model.handle}\n"
            if model.real_name:
                result += f"Name: {model.real_name}\n"
            if model.groups:
                result += f"Groups: {', '.join(model.groups)}"
            return result
        except Exception as e:
            logger.error(f"Error formatting scener: {e}")
            return "Error formatting scener information"

    def _format_event(self, root: ET.Element) -> str:
        """Format event information"""
        try:
            name = root.findtext('.//Event/Name', 'Unknown')
            start_date = root.findtext('.//Event/StartDate', 'Unknown')
            end_date = root.findtext('.//Event/EndDate', None)
            model = CSDBEvent(
                name=name,
                start_date=start_date,
                end_date=end_date
            )
            result = f"Event: {model.name}\n"
            result += f"Start: {model.start_date}\n"
            if model.end_date and model.end_date != model.start_date:
                result += f"End: {model.end_date}"
            return result
        except Exception as e:
            logger.error(f"Error formatting event: {e}")
            return "Error formatting event information"

    def _format_generic(self, root: ET.Element) -> str:
        """Generic XML formatting"""
        return "Entry found (generic format not yet implemented)"

    def _search_help(self, query: str) -> str:
        """
        Provide help on how to search CSDB

        Args:
            query: Original query

        Returns:
            Help text
        """
        return """CSDB Search Usage:

c: release <id>  - Get release info
c: group <id>    - Get group info
c: scener <id>   - Get scener info
c: event <id>    - Get event info

Example:
c: release 1234

Note: IDs can be found by browsing csdb.dk
Full text search coming soon!"""
