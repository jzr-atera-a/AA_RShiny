import heapq
from collections import Counter

from logparse import parse_line


def top_users(lines, k):
    """Return the k users with the most requests, ties broken by name."""
    counts = Counter(r["user"] for r in map(parse_line, lines) if r)
    best = heapq.nlargest(k, counts.items(), key=lambda kv: (kv[1], kv[0]))
    return [user for user, _ in best]
