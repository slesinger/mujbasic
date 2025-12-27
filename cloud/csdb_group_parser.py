from bs4 import BeautifulSoup
from typing import Dict, Any


def parse_csdb_group_detail(html: str) -> Dict[str, Any]:
    soup = BeautifulSoup(html, 'html.parser')
    result = {}
    main = soup.find('td', valign='top', width="100%")
    if not main:
        return result

    # Group name and abbreviation
    name = None
    abbr = None
    heading_font = main.find('font', attrs={'size': '6'})
    if heading_font:
        name = heading_font.get_text(strip=True)
        abbr_tag = heading_font.find_next(
            string=lambda t: t and '(' in t and ')' in t)
        if abbr_tag:
            abbr = abbr_tag.strip().strip('()')
    result['name'] = name
    result['abbreviation'] = abbr

    # Creator and creation date
    creator = None
    creator_id = None
    created_on = None
    creator_font = main.find('font', attrs={'size': '1'})
    if creator_font:
        creator_link = creator_font.find(
            'a', href=lambda h: h and '/scener/?id=' in h)
        if creator_link:
            creator = creator_link.get_text(strip=True)
            creator_id = creator_link['href'].split('=')[-1]
        # Find creation date after <br>On:
        for br in creator_font.find_all('br'):
            if br.next_sibling and 'On:' in br.next_sibling:
                created_on = br.next_sibling.replace('On:', '').strip()
                break
    result['creator'] = creator
    result['creator_id'] = creator_id
    result['created_on'] = created_on

    # Group type
    group_type = None
    for b in main.find_all('b'):
        if 'Group Type' in b.get_text():
            a = b.find_next('a')
            if a:
                group_type = a.get_text(strip=True)
            break
    result['group_type'] = group_type

    # Base country
    country = None
    for b in main.find_all('b'):
        if 'Base Country' in b.get_text():
            a = b.find_next('a')
            if a:
                country = a.get_text(strip=True)
            break
    result['country'] = country

    # User rating
    user_rating = None
    votes_needed = None
    votes_left = None
    vote_url = None
    votestat_url = None
    for b in main.find_all('b'):
        if 'User rating' in b.get_text():
            td = b.parent.find_next('td')
            if td:
                text = td.get_text(' ', strip=True)
                import re
                m = re.search(r'awaiting (\d+) votes \((\d+) left\)', text)
                if m:
                    votes_needed = m.group(1)
                    votes_left = m.group(2)
                # Find vote and statistics links
                vote_a = td.find('a', href=lambda h: h and 'voteview.php' in h)
                if vote_a:
                    vote_url = vote_a['href']
                stat_a = td.find(
                    'a', href=lambda h: h and 'votestatistics.php' in h)
                if stat_a:
                    votestat_url = stat_a['href']
            break
    result['user_rating'] = user_rating
    result['votes_needed'] = votes_needed
    result['votes_left'] = votes_left
    result['vote_url'] = vote_url
    result['votestat_url'] = votestat_url

    # Members
    members = []
    for b in main.find_all('b'):
        if 'All Members' in b.get_text():
            table = b.find_next('table')
            if table:
                for tr in table.find_all('tr'):
                    tds = tr.find_all('td')
                    if len(tds) >= 4:
                        name_a = tds[0].find('a')
                        name = name_a.get_text(
                            strip=True) if name_a else tds[0].get_text(strip=True)
                        status = tds[0].find('small')
                        status_str = status.get_text(
                            strip=True) if status else None
                        roles = tds[3].get_text(strip=True)
                        members.append(
                            {'name': name, 'status': status_str, 'roles': roles})
            break
    result['members'] = members

    return result
