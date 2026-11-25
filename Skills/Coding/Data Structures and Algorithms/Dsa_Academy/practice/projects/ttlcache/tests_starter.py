import unittest

from cache import LRUCache, TTLCache
from fakeclock import FakeClock


class TestCache(unittest.TestCase):
    def test_lru_eviction(self):
        c = LRUCache(2)
        c.put("a", 1); c.put("b", 2); c.get("a"); c.put("c", 3)
        self.assertEqual(c.get("b"), -1)
        self.assertEqual(c.get("a"), 1)

    def test_ttl_fresh_value(self):
        clock = FakeClock()
        c = TTLCache(2, ttl=10, clock=clock)
        c.put("a", 1)
        clock.advance(5)
        self.assertEqual(c.get("a"), 1)

    # TODO: the exact expiry moment, capacity with expired entries, len().


if __name__ == "__main__":
    unittest.main()
