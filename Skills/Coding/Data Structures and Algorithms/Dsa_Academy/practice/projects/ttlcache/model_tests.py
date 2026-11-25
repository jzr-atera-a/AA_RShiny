import unittest

from cache import TTLCache
from fakeclock import FakeClock


class TestTTL(unittest.TestCase):
    def setUp(self):
        self.clock = FakeClock()
        self.c = TTLCache(2, ttl=10, clock=self.clock)

    def test_expires_exactly_at_ttl(self):
        self.c.put("a", 1)
        self.clock.advance(10)
        self.assertEqual(self.c.get("a"), -1)

    def test_put_refreshes(self):
        self.c.put("a", 1); self.clock.advance(8)
        self.c.put("a", 2); self.clock.advance(8)
        self.assertEqual(self.c.get("a"), 2)

    def test_expired_entries_do_not_evict_live_ones(self):
        self.c.put("old", 0)
        self.clock.advance(6)
        self.c.put("x", 1)
        self.clock.advance(1)
        self.c.get("old")                     # "old" becomes most recently used
        self.clock.advance(4)                 # t = 11: "old" has expired, "x" is live
        self.c.put("y", 2)                    # must not evict "x"
        self.assertEqual(self.c.get("x"), 1)

    def test_len_counts_live_entries(self):
        self.c.put("a", 1); self.clock.advance(11)
        self.assertEqual(len(self.c), 0)


if __name__ == "__main__":
    unittest.main()
