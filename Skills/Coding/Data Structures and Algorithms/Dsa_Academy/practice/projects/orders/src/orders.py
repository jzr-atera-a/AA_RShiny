from inventory import Inventory, OutOfStock
from pricing import line_total


class OrderService:
    def __init__(self, inventory, prices):
        self.inventory = inventory      # Inventory
        self.prices = prices            # {sku: unit price in cents}

    def place_order(self, items):
        """items: list of (sku, qty). Takes the stock and returns the total in cents.

        Raises OutOfStock if any line cannot be supplied.
        """
        total = 0
        for sku, qty in items:
            self.inventory.remove(sku, qty)
            total += line_total(self.prices[sku], qty)
        return total
