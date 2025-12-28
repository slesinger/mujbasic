from bs4 import BeautifulSoup
import re
from typing import Dict, Any, List


def parse_csdb_release_detail(html: str) -> Dict[str, Any]:
    soup = BeautifulSoup(html, 'html.parser')
    result: Dict[str, Any] = {
        'name': None,
        'groups': [],
        'release_date': None,
        'type': None,
        'user_rating': None,
        'files': []
    }

    main = soup.find('td', valign='top', width="100%")
    if not main:
        return result

    # Release Name: look for <font size=6> or <font size='+2'>
    name_tag = main.find('font', attrs={'size': '6'})
    if not name_tag:
        name_tag = main.find('font', attrs={'size': '+2'})
    if name_tag:
        result['name'] = name_tag.get_text(strip=True)

    # Released by
    b_released_by = main.find('b', string=lambda t: t and 'Released by' in t)
    if b_released_by:
        next_a = b_released_by.find_next(
            'a', href=lambda h: h and '/group/?id=' in h)
        if next_a:
            group_name = next_a.get_text(strip=True)
            group_id_match = re.search(r'id=(\d+)', next_a['href'])
            group_id = group_id_match.group(1) if group_id_match else None
            result['groups'].append({'id': group_id, 'name': group_name})

    # Release Date
    b_release_date = main.find('b', string=lambda t: t and 'Release Date' in t)
    if b_release_date:
        # The date is in a <font> tag after a <br>
        br = b_release_date.find_next('br')
        if br:
            date_font = br.find_next('font')
            if date_font:
                result['release_date'] = date_font.get_text(strip=True)

    # Type
    b_type = main.find('b', string=lambda t: t and 'Type' in t)
    if b_type:
        next_a = b_type.find_next('a')
        if next_a:
            result['type'] = next_a.get_text(strip=True)

    # User rating
    b_user_rating = main.find('b', string=lambda t: t and 'User rating' in t)
    if b_user_rating:
        rating_text = b_user_rating.parent.find_next('td').get_text(strip=True)
        match = re.search(r'(\d\.\d/\d+)\s*\((\d+)\s*votes\)', rating_text)
        if match:
            result['user_rating'] = f"{match.group(1)} ({match.group(2)} votes)"

    # Files
    download_table = main.find('table', id='downloadLinks')
    if download_table:
        files: List[Dict[str, Any]] = []
        for a in download_table.find_all('a', href=lambda h: h and 'download.php?id=' in h):
            file_info: Dict[str, Any] = {}
            url = a['href']
            id_match = re.search(r'id=(\d+)', url)
            if id_match:
                file_info['id'] = id_match.group(1)

            file_info['name'] = a.get_text(strip=True).split('/')[-1]

            # Downloads and size
            downloads_text = a.next_sibling
            if downloads_text:
                downloads_match = re.search(
                    r'downloads: (\d+)', downloads_text)
                if downloads_match:
                    file_info['downloads'] = downloads_match.group(1)

                size_match = re.search(r'size: (\d+)', downloads_text)
                if size_match:
                    file_info['size'] = int(size_match.group(1))

            files.append(file_info)
        result['files'] = files

    return result
