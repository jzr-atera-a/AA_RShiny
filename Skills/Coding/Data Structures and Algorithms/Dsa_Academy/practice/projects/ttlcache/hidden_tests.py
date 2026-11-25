import unittest

from cache import TTLCache
from fakeclock import FakeClock


class Hidden(unittest.TestCase):
    def mk(self, cap=3, ttl=5):
        self.clock = FakeClock(100.0)
        return TTLCache(cap, ttl=ttl, clock=self.clock)

    def test_basic_get_put(self):
        c = self.mk(); c.put(1, "a")
        self.assertEqual(c.get(1), "a")

    def test_missing(self):
        self.assertEqual(self.mk().get(42), -1)

    def test_alive_just_before_ttl(self):
        c = self.mk(); c.put(1, "a"); self.clock.advance(4.999)
        self.assertEqual(c.get(1), "a")

    def test_dead_at_ttl(self):
        c = self.mk(); c.put(1, "a"); self.clock.advance(5)
        self.assertEqual(c.get(1), -1)

    def test_get_does_not_refresh(self):
        c = self.mk(); c.put(1, "a"); self.clock.advance(3); c.get(1); self.clock.advance(3)
        self.assertEqual(c.get(1), -1)

    def test_put_refreshes(self):
        c = self.mk(); c.put(1, "a"); self.clock.advance(3); c.put(1, "b"); self.clock.advance(3)
        self.assertEqual(c.get(1), "b")

    def test_lru_still_works(self):
        c = self.mk(cap=2, ttl=100); c.put(1, 1); c.put(2, 2); c.get(1); c.put(3, 3)
        self.assertEqual((c.get(1), c.get(2), c.get(3)), (1, -1, 3))

    def test_expired_make_room(self):
        c = self.mk(cap=2, ttl=5)
        c.put(1, 1); self.clock.advance(3); c.put(2, 2); c.get(1); self.clock.advance(3)
        c.put(3, 3)                       # 1 is most recently used but expired; 2 is live
        self.assertEqual((c.get(2), c.get(3)), (2, 3))

    def test_len_live_only(self):
        c = self.mk(); c.put(1, 1); c.put(2, 2); self.clock.advance(6); c.put(3, 3)
        self.assertEqual(len(c), 1)

    def test_invalid_ttl(self):
        with self.assertRaises(ValueError):
            TTLCache(2, ttl=0, clock=FakeClock())

    def test_reinsert_after_expiry(self):
        c = self.mk(); c.put(1, "a"); self.clock.advance(10); c.put(1, "b")
        self.assertEqual(c.get(1), "b")


if __name__ == "__main__":
    unittest.main()
