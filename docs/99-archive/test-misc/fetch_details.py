#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fetch detailed descriptions for key apps - UTF-8 safe output."""
import urllib.request
import urllib.parse
import json
import sys
import io

# Force UTF-8 stdout
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

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

key_searches = [
    ("叨叨", "cn"),
    ("团团记账", "cn"),
    ("木木记账", "cn"),
    ("青子记账", "cn"),
    ("飞鸭AI记账", "cn"),
    ("元元记账", "cn"),
    ("AA账本", "cn"),
]

for term, country in key_searches:
    results, count = search_apps(term, country, 3)
    if results:
        r = results[0]
        print(f"\n{'='*80}")
        print(f"--- {r.get('trackCensoredName')} (id={r.get('trackId')}) ---")
        print(f"{'='*80}")
        print(f"Seller: {r.get('sellerName')}")
        print(f"Bundle: {r.get('bundleId')}")
        print(f"Version: {r.get('version')} | Released: {r.get('currentVersionReleaseDate')}")
        print(f"Rating: {r.get('averageUserRating'):.2f} | Reviews: {r.get('userRatingCount'):,}")
        print(f"Price: {r.get('formattedPrice')}")
        print(f"Genres: {r.get('genres')}")
        print(f"Min OS: {r.get('minimumOsVersion')}")
        print(f"File size: {int(r.get('fileSizeBytes', 0)) / 1024 / 1024:.1f} MB")
        desc = r.get('description', '')
        # Strip newlines from description
        desc_clean = ' '.join(desc.split())[:1500]
        print(f"\nDescription (first 1500 chars):")
        print(desc_clean)
        print(f"\nRelease Notes: {r.get('releaseNotes', 'N/A')}")

# Also try Splitwise in CN store
print("\n\n=== Splitwise in CN App Store ===")
results, count = search_apps('Splitwise', 'cn', 5)
print(f"Result count: {count}")
for r in results:
    print(f"  - {r.get('trackName')} | {r.get('sellerName')} | v{r.get('version')} | rating={r.get('averageUserRating')} | reviews={r.get('userRatingCount')}")

# Try Tricount in CN store
print("\n=== Tricount in CN App Store ===")
results, count = search_apps('tricount', 'cn', 5)
print(f"Result count: {count}")
for r in results:
    print(f"  - {r.get('trackName')} | {r.get('sellerName')} | v{r.get('version')} | rating={r.get('averageUserRating')} | reviews={r.get('userRatingCount')}")

# Try Splid (mentioned in US store)
print("\n=== Splid in various stores ===")
for c in ['cn', 'us', 'gb']:
    results, count = search_apps('Splid', c, 2)
    print(f"  [{c}] count={count}")
    for r in results:
        print(f"    - {r.get('trackName')} | {r.get('sellerName')} | v{r.get('version')} | rating={r.get('averageUserRating')} | reviews={r.get('userRatingCount')}")

# Try KittenSplit / Splitwise alternatives
print("\n=== Other split-bill apps globally ===")
for term in ['Splitwise Pro', 'Split My Bills', 'BillDivider', 'GroupExpense', 'Settle Up', 'Splittr', 'Splito']:
    results, count = search_apps(term, 'us', 2)
    if count > 0:
        print(f"  {term}: count={count}")
        for r in results[:2]:
            print(f"    - {r.get('trackName')} | {r.get('sellerName')} | rating={r.get('averageUserRating')} | reviews={r.get('userRatingCount')}")