from collections import Counter

from textutil import tokenize


class SearchIndex:
    def __init__(self):
        self.postings = {}              # token -> set of doc ids
        self.counts = {}                # doc id -> Counter of tokens

    def add(self, doc_id, text):
        toks = tokenize(text)
        self.counts[doc_id] = Counter(toks)
        for tok in toks:
            self.postings.setdefault(tok, set()).add(doc_id)

    def search(self, query):
        """Ids of documents containing every query token, best match first."""
        terms = tokenize(query)
        sets = [self.postings.get(t, set()) for t in terms]
        if not sets:
            return []
        hits = set.intersection(*sets)
        score = lambda d: sum(self.counts[d][t] for t in terms)
        return sorted(hits, key=lambda d: (-score(d), d))
