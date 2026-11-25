import random
import unittest

from logparse import parse_line
from report import top_users


class Hidden(unittest.TestCase):
    def test_parse_basic(self):
        self.assertEqual(parse_line("t1 ann GET /a 200"), {"ts": "t1", "user": "ann", "method": "GET", "path": "/a", "status": 200})

    def test_parse_messy_whitespace(self):
        self.assertEqual(parse_line("  t1\tann  GET   /a 404 \n")["user"], "ann")

    def test_parse_bad_status(self):
        self.assertIsNone(parse_line("t1 ann GET /a OK"))

    def test_parse_wrong_field_count(self):
        self.assertIsNone(parse_line("t1 ann GET /a 200 extra"))

    def test_top_basic(self):
        lines = ["t a GET / 200"] * 3 + ["t b GET / 200"] * 2 + ["t c GET / 200"]
        self.assertEqual(top_users(lines, 2), ["a", "b"])

    def test_ties_alphabetical(self):
        lines = ["t %s GET / 200" % u for u in ["zoe", "amy", "max", "amy", "zoe", "max"]]
        self.assertEqual(top_users(lines, 2), ["amy", "max"])

    def test_k_zero_and_negative(self):
        self.assertEqual(top_users(["t a GET / 200"], 0), [])
        self.assertEqual(top_users(["t a GET / 200"], -1), [])

    def test_k_too_large(self):
        self.assertEqual(top_users(["t b GET / 200", "t a GET / 200"], 9), ["a", "b"])

    def test_empty(self):
        self.assertEqual(top_users([], 3), [])

    def test_random_against_sort(self):
        rnd = random.Random(5)
        users = ["u%02d" % i for i in range(30)]
        lines = ["t %s GET / 200" % rnd.choice(users) for _ in range(4000)] + ["oops"] * 50
        from collections import Counter
        c = Counter(l.split()[1] for l in lines if len(l.split()) == 5)
        expect = sorted(c, key=lambda u: (-c[u], u))[:7]
        self.assertEqual(top_users(lines, 7), expect)


if __name__ == "__main__":
    unittest.main()
