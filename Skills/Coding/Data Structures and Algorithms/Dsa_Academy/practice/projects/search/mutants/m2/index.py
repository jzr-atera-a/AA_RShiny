from collections import Counter

from textutil import tokenize


class SearchIndex:
    def __init__(self):
        self.postings = {}              # token -> set of doc ids
        self.counts = {}                # doc id -> Counter of tokens

    def add(self, doc_id, text):
        c = Counter(tokenize(text))
        self.counts[doc_id] = c
        for tok in c:
            self.postings.setdefault(tok, set()).add(doc_id)

    def search(self, query):
        """Docs containing every query token; most total occurrences first, then id ascending."""
        terms = tokenize(query)
        if not terms:
            return []
        sets = sorted((self.postings.get(t, set()) for t in set(terms)), key=len)
        hits = set.intersection(*sets)  # smallest set first
        score = {d: sum(self.counts[d][t] for t in terms) for d in hits}
        return sorted(hits, key=lambda d: (-score[d], d))
