---
name: pub-dev-search
description: "Search pub.dev for Dart and Flutter packages and provide recommendations based on quality score, popularity, likes, download counts, and publication recency. Use when a user asks to find, compare, or choose Dart/Flutter packages, or asks 'what package should I use for X' or 'find me a package that does Y' or 'search pub.dev for Z'."
---

# pub.dev Package Search

Search pub.dev and recommend packages using quality metrics.

## Usage

Run the search script with the user's query:

```bash
python3 <skill-dir>/scripts/search_pub_dev.py "<query>" -n <count>
```

- `-n` / `--count`: Number of results (default: 10)
- `--json`: Output structured JSON instead of a table

## Making Recommendations

After running the script, analyze the results and recommend packages. Prioritize:

1. **Quality score** — `grantedPoints/maxPoints` (160/160 is perfect). Prefer packages scoring 140+.
2. **Popularity** — Higher `likes` and `downloads_30d` indicate wider adoption and community trust.
3. **Publication recency** — Recently published packages are more likely to be maintained. Flag packages not updated in over 1 year.
4. **Flutter Favorite** — The `flutter-favorite` flag indicates packages vetted by the Flutter team.
5. **Dart 3 compatible** — The `dart3` flag confirms modern SDK compatibility.

When presenting recommendations:
- Lead with the top 2-3 packages and explain why they stand out.
- Note any trade-offs (e.g., high quality but low popularity, or popular but not recently updated).
- Mention the publisher if it's a well-known one (e.g., `dart.dev`, `google.dev`, `bloclibrary.dev`).
- Call out packages that haven't been updated in over a year as a potential maintenance risk.
