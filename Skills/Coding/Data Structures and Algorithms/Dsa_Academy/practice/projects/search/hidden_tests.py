import unittest

from index import SearchIndex
from textutil import tokenize


class Hidden(unittest.TestCase):
    def test_tokenize_punctuation(self):
        self.assertEqual(tokenize("Hi, there! (ok)"), ["hi", "there", "ok"])

    def test_tokenize_underscore_and_digits(self):
        self.assertEqual(tokenize("user_id=42; v2.0"), ["user", "id", "42", "v2", "0"])

    def test_case_insensitive_search(self):
        ix = SearchIndex(); ix.add(7, "New York City")
        self.assertEqual(ix.search("new YORK"), [7])

    def test_and_semantics(self):
        ix = SearchIndex(); ix.add(1, "a b"); ix.add(2, "a"); ix.add(3, "b")
        self.assertEqual(ix.search("a b"), [1])

    def test_empty_query(self):
        ix = SearchIndex(); ix.add(1, "x")
        self.assertEqual(ix.search(" ,,! "), [])

    def test_unknown_word(self):
        ix = SearchIndex(); ix.add(1, "x")
        self.assertEqual(ix.search("x nope"), [])

    def test_ranking_by_occurrences(self):
        ix = SearchIndex(); ix.add(1, "go go"); ix.add(2, "go go go"); ix.add(3, "go")
        self.assertEqual(ix.search("go"), [2, 1, 3])

    def test_ranking_ties_by_id(self):
        ix = SearchIndex(); ix.add(9, "a b"); ix.add(4, "b a")
        self.assertEqual(ix.search("a b"), [4, 9])

    def test_repeated_query_term(self):
        ix = SearchIndex(); ix.add(1, "a a b"); ix.add(2, "a b b b")
        self.assertEqual(ix.search("a a"), [1, 2])

    def test_readd_replaces_text(self):
        ix = SearchIndex(); ix.add(1, "old words"); ix.add(1, "new words")
        self.assertEqual((ix.search("old"), ix.search("new"), ix.search("words")), ([], [1], [1]))

    def test_readd_changes_rank(self):
        ix = SearchIndex(); ix.add(1, "z z z"); ix.add(2, "z z"); ix.add(1, "z")
        self.assertEqual(ix.search("z"), [2, 1])


if __name__ == "__main__":
    unittest.main()
