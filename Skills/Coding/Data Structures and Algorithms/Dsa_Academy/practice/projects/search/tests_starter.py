import unittest

from index import SearchIndex


class TestIndex(unittest.TestCase):
    def setUp(self):
        self.ix = SearchIndex()
        self.ix.add(1, "the quick brown fox")
        self.ix.add(2, "the lazy dog")

    def test_single_word(self):
        self.assertEqual(self.ix.search("dog"), [2])

    def test_and_semantics(self):
        self.assertEqual(self.ix.search("the fox"), [1])

    # TODO: case, punctuation and underscores, re-adding a document, ranking.


if __name__ == "__main__":
    unittest.main()
