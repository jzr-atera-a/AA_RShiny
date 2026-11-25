from inventory import Inventory, OutOfStock
from pricing import line_total


class OrderService:
    def __init__(self, inventory, prices):
        self.inventory = inventory
        self.prices = prices

    def place_order(self, items):
        total = 0
        for sku, qty in items:
            self.inventory.remove(sku, qty)
            total += line_total(self.prices[sku], qty)
        return total
