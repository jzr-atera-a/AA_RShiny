import unittest

from index import SearchIndex
from textutil import tokenize


class TestIndex(unittest.TestCase):
    def test_tokenize_rules(self):
        self.assertEqual(tokenize("Hello, World! snake_case x2"), ["hello", "world", "snake", "case", "x2"])

    def test_case_insensitive(self):
        ix = SearchIndex(); ix.add(1, "Quick FOX")
        self.assertEqual(ix.search("fox QUICK"), [1])

    def test_readd_replaces(self):
        ix = SearchIndex(); ix.add(1, "red apple"); ix.add(1, "green pear")
        self.assertEqual(ix.search("apple"), [])
        self.assertEqual(ix.search("pear"), [1])

    def test_ranking(self):
        ix = SearchIndex(); ix.add(1, "cat"); ix.add(2, "cat cat dog"); ix.add(3, "cat cat")
        self.assertEqual(ix.search("cat"), [2, 3, 1])


if __name__ == "__main__":
    unittest.main()
