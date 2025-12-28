"""
CSDBHandler - Handles requests to csdb.dk database

Queries the CSDB.dk API for C64 scene information.
Processes requests starting with "c:"
"""
import logging
import os
import requests
import zipfile
import fnmatch
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Optional, List
from pydantic import BaseModel
from base_handler import BaseHandler
from dotenv import load_dotenv
from shared_state import get_session_state
from csdb_group_parser import parse_csdb_group_detail
from csdb_search_parser import parse_csdb_find


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
            logger.info("CSDB authentication enabled.")

    def can_handle(self, text: str, session_id: int = 0) -> bool:
        """
        Only handle if text starts with c:, or if c: is the active module for this session.
        """
        t = text.strip().lower()
        state = get_session_state(session_id)
        if t.startswith("c:"):
            return True
        # Only assume csdb module if user explicitly switched to it
        if state.get('active_module') == 'c':
            # Don't handle if another command is detected
            if any(t.startswith(p) for p in ["i:", "?", "help"]):
                return False
            return True
        return False

    def handle(self, text: str, session_id: int = 0) -> str:
        """
        Process CSDB query or virtual navigation (cd/find/etc) for a session
        """
        t = text.strip()
        t_lower = t.lower()
        state = get_session_state(session_id)

        # If starts with c:, reset module and parse rest
        if t_lower.startswith("c:"):
            state['active_module'] = 'c'
            state['active_dir'] = None
            state['active_id'] = None
            query = t[2:].strip()
            if not query:
                return "CSDB mode"
            return self._process_csdb_command(query, session_id)

        # If c: is active module, interpret commands
        if state.get('active_module') == 'c':
            return self._process_csdb_command(t, session_id)

        # Fallback: not handled
        return "Unknown command. Type 'help' for available commands."

    def _process_csdb_command(self, query: str, session_id: int = 0) -> str:
        """
        Parse and execute a CSDB command string (e.g. 'group 123', 'find foo', etc) for a session
        """
        try:
            return self._parse_and_execute(query, session_id)
        except Exception as e:
            logger.error(f"Error processing CSDB command: {e}")
            return f"Error: {str(e)}"

    def _format_find_result(self, result: dict, custom_section=None) -> str:
        """
        Format a find result dict as text (same as _find_csdb output)
        If custom_section is provided, only format that section: (section, show_all_label, key, count_key)
        """
        if 'error' in result:
            return result['error']

        def fmt_items(items, count, section, show_all_label):
            output = []
            if items:
                output.append(f"{count} {section} matches:")
                for item in items[:10]:  # Limit to 10 items
                    output.append(f"  {item['id']}: {item['name']}")
                if count > 10:
                    output.append(f"  (and {count - 10} more...)")
            return output

        output = []
        if custom_section:
            section, show_all_label, key, count_key = custom_section
            output += fmt_items(result.get(key, []),
                                result.get(count_key, 0), section, show_all_label)
        else:
            output += fmt_items(result.get('releases', []),
                                result.get('release_count', 0), 'release matches', 'releases')
            output += fmt_items(result.get('groups', []),
                                result.get('group_count', 0), "group", "groups")
            output.extend(fmt_items(result.get('sceners', []), result.get(
                'scener_count', 0), "scener", "sceners"))
        return '\n'.join(output) if output else "No results found."

    def _cp_file(self, file_pattern: str, session_id: int) -> str:
        """Copy file(s) from a release or zip."""
        state = get_session_state(session_id)
        if not state.get('active_dir') == 'release' or not state.get('active_id'):
            return "cp can only be used within a release."

        output = []
        tmp_dir = Path("/tmp/c64cloud")
        tmp_dir.mkdir(exist_ok=True)

        if state.get('zip_id') and state.get('zip_files'):
            # Copy from zip
            zip_path = tmp_dir / f"{state['zip_id']}.zip"
            if not zip_path.exists():
                return f"Zip file for {state['zip_id']} not found."
            with zipfile.ZipFile(zip_path, 'r') as z:
                for f in state['zip_files']:
                    if fnmatch.fnmatch(f, file_pattern):
                        z.extract(f, path=tmp_dir)
                        output.append(f"Copied {f} to /tmp/c64cloud")
        else:
            # Copy from release
            release_info = self._get_parsed_release_info(state['active_id'])
            if not release_info or 'files' not in release_info:
                return "No files found for this release."

            for f in release_info['files']:
                if fnmatch.fnmatch(f['name'], file_pattern):
                    download_url = f"{CSDB_API_URL}?request=download&id={f['id']}"
                    try:
                        response = self.session.get(download_url)
                        response.raise_for_status()
                        file_path = tmp_dir / f['name']
                        with open(file_path, 'wb') as out_file:
                            out_file.write(response.content)
                        output.append(f"Copied {f['name']} to /tmp/c64cloud")
                    except requests.exceptions.RequestException as e:
                        output.append(f"Failed to download {f['name']}: {e}")

        return '\n'.join(output) if output else "No files copied."

    def _cd_into_zip(self, file_id: int, session_id: int) -> str:
        """Download and extract a zip file, listing its contents."""
        state = get_session_state(session_id)
        download_url = f"{CSDB_API_URL}?request=download&id={file_id}"
        tmp_dir = Path("/tmp/c64cloud")
        tmp_dir.mkdir(exist_ok=True)
        zip_path = tmp_dir / f"{file_id}.zip"

        try:
            response = self.session.get(download_url)
            response.raise_for_status()
            with open(zip_path, 'wb') as f:
                f.write(response.content)

            with zipfile.ZipFile(zip_path, 'r') as z:
                files = z.namelist()
                state['zip_id'] = file_id
                state['zip_files'] = files
                return "Contents of zip:\n" + "\n".join(f"  - {f}" for f in files)

        except requests.exceptions.RequestException as e:
            return f"Failed to download zip: {e}"
        except zipfile.BadZipFile:
            return "Downloaded file is not a valid zip archive."
        except Exception as e:
            logger.error(f"Error handling zip: {e}")
            return "An error occurred while processing the zip file."

    def _query_csdb(self, query: str) -> str:
        """
        Make a raw query to the CSDB webservice and return raw response
        """
        try:
            response = self.session.get(f"{CSDB_API_URL}?{query}")
            response.raise_for_status()
            return response.text
        except requests.exceptions.RequestException as e:
            logger.error(f"CSDB query failed: {e}")
            return f"Error: Could not connect to CSDB ({e})"

    def _find_csdb(self, search_text: str) -> dict:
        """
        Perform CSDB find (HTML search) and return parsed result dict
        """
        url = f"https://csdb.dk/search/?seinsel=all&search={search_text}&Go.x=8&Go.y=9"
        try:
            resp = requests.get(url, timeout=10)
            resp.raise_for_status()
            html = resp.text
        except requests.RequestException as e:
            return {'error': f"Network error: {str(e)}"}

        return parse_csdb_find(html)

    def _get_entry_info(self, entry_type: str, entry_id: int, session_id: int, depth: int = 2) -> str:
        def format_members(members: list) -> str:
            if not members:
                return "(none)"

            lines = []
            for m in members:
                member_id = m.get('id') or ''
                name = m.get('name', '')
                status = m.get('status') or ''
                if status:
                    status = f"({status})"
                roles = m.get('roles') or ''

                # Format: id (padded) name (status) - roles
                details = f"{name} {status} - {roles}".strip()
                line = f"{member_id:<6} {details}"
                lines.append(line[:40])
            return '\n'.join(lines)

        def format_release_output(release_data: dict, entry_id: int) -> str:
            """Format release output from HTML parser data"""

            output = []
            # Add release name as heading if present
            release_name = release_data.get('name')
            if release_name:
                output.append(f"Release: {release_name}")

            # Released by: group_id    group_name
            if release_data.get('groups'):
                groups_parts = []
                for group in release_data['groups']:
                    group_id = group.get('id', '')
                    group_name = group.get('name', '')
                    if group_id and group_name:
                        groups_parts.append(f"{group_id} {group_name}")
                if groups_parts:
                    output.append(f"Released by: {', '.join(groups_parts)}")

            # Release Date
            if release_data.get('release_date'):
                output.append(f"Release Date: {release_data['release_date']}")

            # Type
            if release_data.get('type'):
                output.append(f"Type: {release_data['type']}")

            # User rating
            if release_data.get('user_rating'):
                output.append(f"User rating: {release_data['user_rating']}")

            # Files
            files = release_data.get('files', [])
            if files:
                output.append("\nFiles:")
                for f in files:
                    size_str = f" ({f['size']})" if 'size' in f else ""
                    output.append(
                        f"{f.get('id', '')} {f.get('name', '')}{size_str} ({f.get('downloads', 'N/A')} d/l)")

            return '\n'.join(output)

        def format_scener_output(model: CSDBScener) -> str:
            result = f"Handle: {model.handle}\n"
            if model.real_name:
                result += f"Name: {model.real_name}\n"
            if model.groups:
                result += f"Groups: {', '.join(model.groups)}"
            return result

        def format_event_output(model: CSDBEvent) -> str:
            result = f"Event: {model.name}\n"
            result += f"Start: {model.start_date}\n"
            if model.end_date and model.end_date != model.start_date:
                result += f"End: {model.end_date}"
            return result

        def format_group_output(group_data: dict, entry_id: int) -> str:
            name = group_data.get('name', f"Group {entry_id}")
            abbr = group_data.get('abbreviation')
            country = group_data.get('country')
            group_type = group_data.get('group_type')
            user_rating = group_data.get('user_rating')
            # Compose the first line: name (abbr) [country]
            first_line = f"{name}"
            if abbr:
                first_line += f" ({abbr})"
            if country:
                first_line += f" [{country}]"
            output = [first_line]
            type_rating_line = None
            if group_type and user_rating:
                type_rating_line = f"Type: {group_type} | Rating: {user_rating}"
            elif group_type:
                type_rating_line = f"Type: {group_type}"
            elif user_rating:
                type_rating_line = f"Rating: {user_rating}"
            if type_rating_line:
                output.append(type_rating_line)
            output.append("")
            # Only add 'All Members:' if there are members
            members = group_data.get('members', [])
            if members:
                output.append("All Members:")
                output.append(format_members(members))
                output.append("")

            # Add 'Releases' section if present
            releases = group_data.get('releases', [])
            if releases:
                output.append(f"Releases: ({len(releases)})")

                def format_release(r):
                    title = r.get('title', 'Unknown')
                    year = r.get('year')
                    release_type = r.get('type')
                    release_id = r.get('id', '')

                    year_str = f"({year})" if year else ""
                    type_str = f"[{release_type}]" if release_type else ""

                    # Format: id (padded) title (year) [type]
                    full_title = f"{title} {year_str} {type_str}".strip()
                    line = f"{release_id:<6} {full_title}"
                    return line[:40]

                for rel in releases:
                    output.append(format_release(rel))
                output.append("")
            return '\n'.join(output)
        """
        Get information for a specific CSDB entry
        For 'group' and 'release', use HTML parser for detailed information.
        """
        state = get_session_state(session_id)
        if state.get('zip_id') and state.get('zip_files'):
            return "Contents of zip file:\n" + '\n'.join(state['zip_files'])

        if entry_type == 'group':
            try:
                url = f"https://csdb.dk/group/?id={entry_id}"
                logger.info(f"Fetching group HTML for id {entry_id}: {url}")
                resp = self.session.get(url, timeout=10)
                resp.raise_for_status()
                group_data = parse_csdb_group_detail(resp.text)
                return format_group_output(group_data, entry_id)
            except Exception as e:
                return f"Error parsing group page: {e}"

        if entry_type == 'release':
            try:
                release_data = self._get_parsed_release_info(entry_id)
                if 'error' in release_data:
                    return release_data['error']
                return format_release_output(release_data, entry_id)
            except Exception as e:
                return f"Error parsing release page: {e}"

        try:
            params = {
                'type': entry_type,
                'id': entry_id,
                'depth': min(depth, 4)
            }
            logger.info(f"Fetching {entry_type} {entry_id} from CSDB XML API")
            response = self.session.get(
                CSDB_API_URL, params=params, timeout=10)
            response.raise_for_status()
            root = ET.fromstring(response.content)
            if entry_type == 'release':
                # This code path should not be reached anymore
                name = root.findtext('.//Release/Name', 'Unknown')
                release_type = root.findtext('.//Release/Type', 'Unknown')
                release_date = root.findtext(
                    './/Release/ReleaseDate', 'Unknown')
                groups = [group.findtext('Name', 'Unknown') for group in root.findall(
                    './/Release/ReleasedBy/Group')]
                model = CSDBRelease(
                    name=name,
                    release_type=release_type,
                    release_date=release_date,
                    groups=groups
                )
                return format_release_output({}, entry_id)
            elif entry_type == 'scener':
                handle = root.findtext('.//Scener/Handle', 'Unknown')
                real_name = root.findtext('.//Scener/RealName', None)
                groups = [group.findtext('Name', 'Unknown')
                          for group in root.findall('.//Scener/Groups/Group')]
                model = CSDBScener(
                    handle=handle,
                    real_name=real_name,
                    groups=groups
                )
                return format_scener_output(model)
            elif entry_type == 'event':
                name = root.findtext('.//Event/Name', 'Unknown')
                start_date = root.findtext('.//Event/StartDate', 'Unknown')
                end_date = root.findtext('.//Event/EndDate', None)
                model = CSDBEvent(
                    name=name,
                    start_date=start_date,
                    end_date=end_date
                )
                return format_event_output(model)
            else:
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

    def _get_parsed_release_info(self, release_id: int) -> dict:
        """Helper to get parsed release info from HTML."""
        from csdb_release_parser import parse_csdb_release_detail
        url = f"https://csdb.dk/release/?id={release_id}"
        try:
            resp = self.session.get(url, timeout=10)
            resp.raise_for_status()
            html = resp.text
        except requests.RequestException as e:
            return {'error': f"Network error getting release info: {e}"}

        return parse_csdb_release_detail(html)

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

Navigation:
c: find <text>   - Search for releases, groups, etc.
c: cd <type>     - Change directory (e.g., 'cd release')
c: cd <id>       - View details of an item
c: cd ..         - Go up one level
c: pwd           - Show current path
c: cp <file>     - Copy file from a release to local tmp
exit            - Exit interactive mode"""

    def _parse_and_execute(self, command: str, session_id: int) -> str:
        """
        Parse and execute a command in the context of a session's CSDB state.
        """
        state = get_session_state(session_id)
        parts = command.strip().split(maxsplit=1)
        cmd = parts[0].lower() if parts else ''
        arg = parts[1] if len(parts) > 1 else ''

        # PWD
        if cmd == 'pwd':
            path = "c:/"
            if state.get('active_dir'):
                path += state['active_dir']
            if state.get('active_id'):
                path += f"/{state['active_id']}"
            return path

        # EXIT
        if cmd == 'exit':
            state['active_module'] = None
            return "Exited CSDB mode."

        # CD
        if cmd == 'cd':
            if not arg:
                return "Usage: cd <type>, cd <id>, or cd /<type>/<id>"

            # Handle path-like cd, e.g. /release/12345 or /release/12345/67890
            if arg.startswith('/'):
                path_parts = [p for p in arg.split('/') if p]
                if len(path_parts) == 2 and path_parts[0].lower() in ['release', 'group', 'scener', 'event', 'bbs', 'sid'] and path_parts[1].isdigit():
                    state['active_dir'] = path_parts[0].lower()
                    state['active_id'] = int(path_parts[1])
                    return self._get_entry_info(state['active_dir'], state['active_id'], session_id)
                elif len(path_parts) == 3 and path_parts[0].lower() == 'release' and path_parts[1].isdigit() and path_parts[2].isdigit():
                    state['active_dir'] = 'release'
                    state['active_id'] = int(path_parts[1])
                    # This is likely a zip file inside a release, attempt to cd into it
                    return self._cd_into_zip(int(path_parts[2]), session_id)
                else:
                    return f"Invalid path format: {arg}"

            # cd <type>
            if arg.lower() in ['release', 'group', 'scener', 'event', 'bbs', 'sid']:
                state['active_dir'] = arg.lower()
                state['active_id'] = None
                return f"Switched to {state['active_dir']} directory."
            # cd <id>
            if arg.isdigit():
                if not state.get('active_dir'):
                    return "Cannot cd into an ID without a directory context. Use 'cd <type>' first."
                state['active_id'] = int(arg)
                return self._get_entry_info(state['active_dir'], state['active_id'], session_id)
            # cd <zip_file_id>
            if arg.lower().endswith('.zip') and state.get('active_dir') == 'release' and state.get('active_id'):
                release_info = self._get_parsed_release_info(state['active_id'])
                file_id = None
                for f in release_info.get('files', []):
                    if f['name'].lower() == arg.lower():
                        file_id = f['id']
                        break
                if file_id:
                    return self._cd_into_zip(file_id, session_id)
                else:
                    return f"Zip file '{arg}' not found in this release."

            return f"Invalid 'cd' argument: {arg}"

        # FIND / LS
        if cmd in ['find', 'ls']:
            search_text = arg if cmd == 'find' else (state.get('last_find', '') if 'ls' else '')
            if not search_text and not state.get('active_dir'):
                return "Usage: find <text>"
            state['last_find'] = search_text

            if state.get('active_dir'):
                # Search within a specific directory
                full_query = f"{state['active_dir']} {search_text}".strip()
                result = self._find_csdb(full_query)
                return self._format_find_result(result, custom_section=(
                    state['active_dir'], f"{state['active_dir']}s", state['active_dir']+'s', state['active_dir']+'_count'))
            else:
                # Global search
                result = self._find_csdb(search_text)
                return self._format_find_result(result)

        # CP
        if cmd == 'cp':
            if not arg:
                return "Usage: cp <file_pattern>"
            return self._cp_file(arg, session_id)

        # Direct queries (e.g., "release 123")
        if cmd in ['release', 'group', 'scener', 'event'] and arg.isdigit():
            return self._get_entry_info(cmd, int(arg), session_id)

        # Fallback to a general find
        return self._format_find_result(self._find_csdb(command))
