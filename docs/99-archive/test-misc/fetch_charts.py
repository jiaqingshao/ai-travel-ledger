#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Try Apple's RSS chart feed for top finance apps in CN."""
import urllib.request
import urllib.parse
import json
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

# Apple's RSS chart feed format (works without auth!)
# Top Free: https://rss.applemarketingtools.com/api/v2/cn/apps/top-free/50/apps.json
# Top Paid: https://rss.applemarketingtools.com/api/v2/cn/apps/top-paid/50/apps.json
# Top Grossing: https://rss.applemarketingtools.com/api/v2/cn/apps/top-grossing/50/apps.json

urls = {
    'CN Top Free (all)': 'https://rss.applemarketingtools.com/api/v2/cn/apps/top-free/50/apps.json',
    'CN Top Paid (all)': 'https://rss.applemarketingtools.com/api/v2/cn/apps/top-paid/50/apps.json',
    'CN Top Grossing (all)': 'https://rss.applemarketingtools.com/api/v2/cn/apps/top-grossing/50/apps.json',
    'CN Top Free Finance': 'https://rss.applemarketingtools.com/api/v2/cn/finance/apps/top-free/50/apps.json',
    'CN Top Paid Finance': 'https://rss.applemarketingtools.com/api/v2/cn/finance/apps/top-paid/50/apps.json',
    'CN Top Grossing Finance': 'https://rss.applemarketingtools.com/api/v2/cn/finance/apps/top-grossing/50/apps.json',
    'US Top Free Finance': 'https://rss.applemarketingtools.com/api/v2/us/finance/apps/top-free/50/apps.json',
    'US Top Paid Finance': 'https://rss.applemarketingtools.com/api/v2/us/finance/apps/top-paid/50/apps.json',
    'US Top Grossing Finance': 'https://rss.applemarketingtools.com/api/v2/us/finance/apps/top-grossing/50/apps.json',
}

for label, url in urls.items():
    print(f"\n=== {label} ===")
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=20) as resp:
            data = json.loads(resp.read().decode('utf-8'))
        results = data.get('feed', {}).get('results', [])
        print(f"  Count: {len(results)}")
        for i, r in enumerate(results[:25], 1):
            name = r.get('name', 'N/A')
            artist = r.get('artistName', 'N/A')
            genres = r.get('genres', [])
            print(f"  {i:>3}. {name:<40} | {artist[:30]:<30} | genres={genres}")
    except Exception as e:
        print(f"  ERROR: {e}")