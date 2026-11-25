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

    def test_out_of_stock_raises(self):
        with self.assertRaises(OutOfStock):
            self.svc.place_order([("pear", 6)])

    # TODO: add tests for the bulk-discount boundary and for orders that fail part-way.


if __name__ == "__main__":
    unittest.main()
