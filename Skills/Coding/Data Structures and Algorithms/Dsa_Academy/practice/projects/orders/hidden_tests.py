import unittest

from inventory import Inventory, OutOfStock
from orders import OrderService


def make():
    inv = Inventory({"a": 100, "b": 5, "c": 12})
    return inv, OrderService(inv, {"a": 100, "b": 999, "c": 333})


class Hidden(unittest.TestCase):
    def test_plain_order_total(self):
        inv, s = make()
        self.assertEqual(s.place_order([("a", 3), ("b", 1)]), 1299)

    def test_stock_is_taken(self):
        inv, s = make()
        s.place_order([("a", 3), ("b", 1)])
        self.assertEqual((inv.available("a"), inv.available("b")), (97, 4))

    def test_bulk_discount_at_ten(self):
        inv, s = make()
        self.assertEqual(s.place_order([("a", 10)]), 900)

    def test_bulk_discount_below_ten(self):
        inv, s = make()
        self.assertEqual(s.place_order([("a", 9)]), 900)

    def test_bulk_discount_rounds_down(self):
        inv, s = make()
        self.assertEqual(s.place_order([("c", 11)]), 3296)

    def test_atomic_when_second_line_fails(self):
        inv, s = make()
        with self.assertRaises(OutOfStock):
            s.place_order([("a", 5), ("b", 6)])
        self.assertEqual(inv.available("a"), 100)

    def test_atomic_with_repeated_sku(self):
        inv, s = make()
        with self.assertRaises(OutOfStock):
            s.place_order([("b", 3), ("a", 1), ("b", 3)])
        self.assertEqual((inv.available("a"), inv.available("b")), (100, 5))

    def test_repeated_sku_that_fits(self):
        inv, s = make()
        self.assertEqual(s.place_order([("b", 2), ("b", 3)]), 999 * 5)
        self.assertEqual(inv.available("b"), 0)

    def test_unknown_sku_takes_nothing(self):
        inv, s = make()
        with self.assertRaises(KeyError):
            s.place_order([("a", 1), ("zzz", 1)])
        self.assertEqual(inv.available("a"), 100)


if __name__ == "__main__":
    unittest.main()
