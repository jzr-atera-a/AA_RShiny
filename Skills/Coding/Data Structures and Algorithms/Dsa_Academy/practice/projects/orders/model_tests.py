import unittest

from inventory import Inventory, OutOfStock
from orders import OrderService


class TestOrders(unittest.TestCase):
    def setUp(self):
        self.inv = Inventory({"apple": 30, "pear": 5})
        self.svc = OrderService(self.inv, {"apple": 120, "pear": 255})

    def test_simple_order(self):
        self.assertEqual(self.svc.place_order([("apple", 2)]), 240)
        self.assertEqual(self.inv.available("apple"), 28)

    def test_no_discount_below_threshold(self):
        self.assertEqual(self.svc.place_order([("apple", 9)]), 1080)

    def test_discount_exactly_at_threshold(self):          # catches '> 10'
        self.assertEqual(self.svc.place_order([("apple", 10)]), 1080)

    def test_discount_rounds_down(self):
        self.assertEqual(self.svc.place_order([("pear", 5), ("apple", 1)]), 1275 + 120)
        inv = Inventory({"x": 50})
        svc = OrderService(inv, {"x": 333})
        self.assertEqual(svc.place_order([("x", 11)]), 3296)   # 3663 * 0.9 = 3296.7 → 3296

    def test_failure_leaves_stock_untouched(self):
        with self.assertRaises(OutOfStock):
            self.svc.place_order([("apple", 3), ("pear", 6)])
        self.assertEqual(self.inv.available("apple"), 30)

    def test_same_sku_on_two_lines(self):                   # catches the per-line pre-check
        with self.assertRaises(OutOfStock):
            self.svc.place_order([("pear", 3), ("pear", 3)])
        self.assertEqual(self.inv.available("pear"), 5)


if __name__ == "__main__":
    unittest.main()
