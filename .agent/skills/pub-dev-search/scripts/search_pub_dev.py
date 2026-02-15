#!/usr/bin/env python3
"""Search pub.dev for packages and display recommendations with metrics."""

import argparse
import json
import sys
import urllib.request
import urllib.parse
from datetime import datetime, timezone

BASE_URL = "https://pub.dev/api"


def search_packages(query, page=1):
    """Search pub.dev for packages matching the query."""
    params = urllib.parse.urlencode({"q": query, "page": page})
    url = f"{BASE_URL}/search?{params}"
    req = urllib.request.Request(url, headers={"Accept": "application/json"})
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode())


def get_package_score(package_name):
    """Get the score/metrics for a package."""
    url = f"{BASE_URL}/packages/{urllib.parse.quote(package_name)}/metrics"
    req = urllib.request.Request(url, headers={"Accept": "application/json"})
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode())


def get_package_info(package_name):
    """Get package details including description and latest version."""
    url = f"{BASE_URL}/packages/{urllib.parse.quote(package_name)}"
    req = urllib.request.Request(url, headers={"Accept": "application/json"})
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode())


def format_date(date_str):
    """Format an ISO date string to a readable format and days ago."""
    dt = datetime.fromisoformat(date_str.replace("Z", "+00:00"))
    now = datetime.now(timezone.utc)
    days_ago = (now - dt).days
    if days_ago == 0:
        age = "today"
    elif days_ago == 1:
        age = "1 day ago"
    elif days_ago < 30:
        age = f"{days_ago} days ago"
    elif days_ago < 365:
        months = days_ago // 30
        age = f"{months} month{'s' if months != 1 else ''} ago"
    else:
        years = days_ago // 365
        age = f"{years} year{'s' if years != 1 else ''} ago"
    return dt.strftime("%Y-%m-%d"), age


def format_downloads(count):
    """Format download count with K/M suffixes."""
    if count >= 1_000_000:
        return f"{count / 1_000_000:.1f}M"
    elif count >= 1_000:
        return f"{count / 1_000:.1f}K"
    return str(count)


def main():
    parser = argparse.ArgumentParser(description="Search pub.dev packages")
    parser.add_argument("query", help="Search query")
    parser.add_argument(
        "-n", "--count", type=int, default=10, help="Number of results (default: 10)"
    )
    parser.add_argument(
        "--json", action="store_true", dest="json_output", help="Output as JSON"
    )
    args = parser.parse_args()

    # Search for packages
    results = search_packages(args.query)
    packages = results.get("packages", [])

    if not packages:
        print(f"No packages found for '{args.query}'")
        sys.exit(0)

    packages = packages[: args.count]

    # Fetch details for each package
    pkg_data = []
    for pkg in packages:
        name = pkg["package"]
        info = get_package_info(name)
        metrics = get_package_score(name)

        latest = info.get("latest", {})
        pubspec = latest.get("pubspec", {})
        score = metrics.get("score", {})

        published = latest.get("published", "")
        pub_date, pub_age = format_date(published) if published else ("unknown", "")

        granted = score.get("grantedPoints", 0)
        max_pts = score.get("maxPoints", 0)
        quality_pct = round(granted / max_pts * 100) if max_pts > 0 else 0
        likes = score.get("likeCount", 0)
        downloads_30d = score.get("downloadCount30Days", 0)
        tags = score.get("tags", [])

        is_flutter_fav = "is:flutter-favorite" in tags
        is_dart3 = "is:dart3-compatible" in tags

        pkg_data.append(
            {
                "name": name,
                "version": latest.get("version", "?"),
                "description": pubspec.get("description", ""),
                "publisher": next(
                    (
                        t.split(":")[1]
                        for t in tags
                        if t.startswith("publisher:")
                    ),
                    "",
                ),
                "quality_points": f"{granted}/{max_pts}",
                "quality_pct": quality_pct,
                "likes": likes,
                "downloads_30d": downloads_30d,
                "published_date": pub_date,
                "published_age": pub_age,
                "flutter_favorite": is_flutter_fav,
                "dart3_compatible": is_dart3,
                "sdks": [
                    t.split(":")[1] for t in tags if t.startswith("sdk:")
                ],
                "platforms": [
                    t.split(":")[1] for t in tags if t.startswith("platform:")
                ],
            }
        )

    if args.json_output:
        print(json.dumps(pkg_data, indent=2))
        return

    # Print formatted table
    print(f"\n## pub.dev results for '{args.query}'\n")
    print(
        f"{'#':<3} {'Package':<30} {'Version':<12} {'Quality':<10} "
        f"{'Likes':<8} {'Downloads/30d':<15} {'Published':<25} {'Flags'}"
    )
    print("-" * 120)

    for i, p in enumerate(pkg_data, 1):
        flags = []
        if p["flutter_favorite"]:
            flags.append("flutter-favorite")
        if p["dart3_compatible"]:
            flags.append("dart3")

        print(
            f"{i:<3} {p['name']:<30} {p['version']:<12} "
            f"{p['quality_points']:<10} {p['likes']:<8} "
            f"{format_downloads(p['downloads_30d']):<15} "
            f"{p['published_date'] + ' (' + p['published_age'] + ')':<25} "
            f"{', '.join(flags)}"
        )
        # Print description on next line, truncated
        desc = p["description"][:100] + ("..." if len(p["description"]) > 100 else "")
        print(f"    {desc}")
        if p["publisher"]:
            print(f"    Publisher: {p['publisher']}")
        if p["platforms"]:
            print(f"    Platforms: {', '.join(p['platforms'])}")
        print()


if __name__ == "__main__":
    main()
