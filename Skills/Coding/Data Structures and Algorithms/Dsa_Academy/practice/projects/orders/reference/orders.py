from collections import Counter

from inventory import Inventory, OutOfStock
from pricing import line_total


class OrderService:
    def __init__(self, inventory, prices):
        self.inventory = inventory      # Inventory
        self.prices = prices            # {sku: unit price in cents}

    def place_order(self, items):
        """items: list of (sku, qty). Takes the stock and returns the total in cents.

        Atomic: raises OutOfStock (or KeyError for an unknown sku) without taking any stock.
        """
        need = Counter()
        for sku, qty in items:
            if qty <= 0:
                raise ValueError("qty must be positive")
            if sku not in self.prices:
                raise KeyError(sku)
            need[sku] += qty                      # the same sku may appear on several lines
        for sku, qty in need.items():
            if self.inventory.available(sku) < qty:
                raise OutOfStock(sku)
        total = 0
        for sku, qty in items:                    # cannot fail any more
            self.inventory.remove(sku, qty)
            total += line_total(self.prices[sku], qty)
        return total
