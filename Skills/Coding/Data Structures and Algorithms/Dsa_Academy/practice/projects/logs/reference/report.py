import heapq
from collections import Counter

from logparse import parse_line


def top_users(lines, k):
    """k users with the most requests; ties by name ascending; malformed lines skipped."""
    if k <= 0:
        return []
    counts = Counter(r["user"] for r in map(parse_line, lines) if r)
    # nsmallest on (-count, name) gives "most requests first, then alphabetical"
    return [u for u, _ in heapq.nsmallest(k, counts.items(), key=lambda kv: (-kv[1], kv[0]))]
