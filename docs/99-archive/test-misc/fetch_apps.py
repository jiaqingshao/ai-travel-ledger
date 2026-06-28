#!/usr/bin/env python3
"""Fetch iTunes Search API data for various apps and print summary."""
import urllib.request
import urllib.parse
import json
import sys

def search_apps(term, country='cn', limit=20):
    url = f"https://itunes.apple.com/search?{urllib.parse.urlencode({'term': term, 'country': country, 'entity': 'software', 'limit': limit})}"
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=20) as resp:
            data = json.loads(resp.read().decode('utf-8'))
        return data.get('results', []), data.get('resultCount', 0)
    except Exception as e:
        print(f"  ERROR fetching: {e}", file=sys.stderr)
        return [], 0

def print_results(results, count, label):
    print(f"\n=== {label} ===")
    print(f"Result count: {count}")
    print(f"{'#':<3} {'Name':<38} {'Rating':<7} {'Reviews':<10} {'Version':<10} {'Released':<11} {'Seller'}")
    print('-' * 130)
    for i, r in enumerate(results, 1):
        name = (r.get('trackCensoredName') or r.get('trackName') or 'N/A')[:36]
        rating = r.get('averageUserRating') or 0
        reviews = r.get('userRatingCount') or 0
        version = r.get('version') or 'N/A'
        released = (r.get('currentVersionReleaseDate') or 'N/A')[:10]
        seller = (r.get('sellerName') or r.get('artistName') or 'N/A')[:30]
        print(f"{i:<3} {name:<38} {rating:<7.2f} {reviews:<10,} {version:<10} {released:<11} {seller}")

# Search 1: 记账 (accounting) in CN
results, count = search_apps('记账', 'cn', 20)
print_results(results, count, "CN - 记账")

# Search 2: 百事AA记账
results, count = search_apps('百事', 'cn', 10)
print_results(results, count, "CN - 百事")

# Search 3: AA账本
results, count = search_apps('AA账本', 'cn', 10)
print_results(results, count, "CN - AA账本")

# Search 4: 圈子账本
results, count = search_apps('圈子账本', 'cn', 10)
print_results(results, count, "CN - 圈子账本")

# Search 5: 叨叨记账
results, count = search_apps('叨叨记账', 'cn', 10)
print_results(results, count, "CN - 叨叨记账")

# Search 6: 钱迹
results, count = search_apps('钱迹', 'cn', 10)
print_results(results, count, "CN - 钱迹")

# Search 7: 来福记账
results, count = search_apps('来福记账', 'cn', 10)
print_results(results, count, "CN - 来福记账")

# Search 8: AI记账
results, count = search_apps('AI记账', 'cn', 10)
print_results(results, count, "CN - AI记账")

# Search 9: 旅账
results, count = search_apps('旅账', 'cn', 10)
print_results(results, count, "CN - 旅账")

# Search 10: 鲨鱼记账 (already saw it - need to confirm)
results, count = search_apps('鲨鱼记账', 'cn', 5)
print_results(results, count, "CN - 鲨鱼记账")

# Search 11: Splitwise in US (already saw it - need full data)
results, count = search_apps('Splitwise', 'us', 3)
print_results(results, count, "US - Splitwise")

# Search 12: Tricount in US (already saw it - need full data)
results, count = search_apps('tricount', 'us', 3)
print_results(results, count, "US - Tricount")