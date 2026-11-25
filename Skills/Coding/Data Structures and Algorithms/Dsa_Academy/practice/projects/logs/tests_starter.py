import unittest

from logparse import parse_line
from report import top_users

LOG = [
    "2024-05-01T10:00:00 alice GET /home 200",
    "2024-05-01T10:00:01 bob GET /home 200",
    "2024-05-01T10:00:02 alice POST /cart 201",
]


class TestReport(unittest.TestCase):
    def test_parse_valid(self):
        self.assertEqual(parse_line(LOG[0])["user"], "alice")

    def test_parse_malformed(self):
        self.assertIsNone(parse_line("garbage"))

    def test_top_one(self):
        self.assertEqual(top_users(LOG, 1), ["alice"])

    # TODO: ties, k larger than the number of users, k = 0, messy whitespace.


if __name__ == "__main__":
    unittest.main()
