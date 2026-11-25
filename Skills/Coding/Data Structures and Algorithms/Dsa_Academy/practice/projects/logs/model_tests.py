import unittest

from logparse import parse_line
from report import top_users

LOG = [
    "2024-05-01T10:00:00 alice GET /home 200",
    "2024-05-01T10:00:01 bob GET /home 200",
    "2024-05-01T10:00:02 alice POST /cart 201",
    "2024-05-01T10:00:03 carol GET /home 500",
    "2024-05-01T10:00:04 bob GET /about 200",
]


class TestReport(unittest.TestCase):
    def test_parse_extra_spaces_and_newline(self):
        r = parse_line("2024-05-01T10:00:00   dave\tGET /x  404\n")
        self.assertEqual((r["user"], r["status"]), ("dave", 404))

    def test_tie_broken_alphabetically(self):
        self.assertEqual(top_users(LOG, 2), ["alice", "bob"])
        self.assertEqual(top_users(["t u2 GET / 200", "t u1 GET / 200"], 1), ["u1"])

    def test_k_larger_than_users(self):
        self.assertEqual(top_users(LOG, 10), ["alice", "bob", "carol"])

    def test_k_zero(self):
        self.assertEqual(top_users(LOG, 0), [])

    def test_malformed_lines_skipped(self):
        self.assertEqual(top_users(["", "bad line", "t zed GET / 200"], 5), ["zed"])


if __name__ == "__main__":
    unittest.main()
