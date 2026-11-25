from textutil import tokenize


class SearchIndex:
    def __init__(self):
        self.postings = {}              # token -> set of doc ids

    def add(self, doc_id, text):
        for tok in tokenize(text):
            self.postings.setdefault(tok, set()).add(doc_id)

    def search(self, query):
        """Ids of documents that contain every query token, ascending."""
        sets = [self.postings.get(t, set()) for t in tokenize(query)]
        if not sets:
            return []
        return sorted(set.intersection(*sets))
