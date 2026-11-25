"""Warehouse stock levels."""


class OutOfStock(Exception):
    """Raised when an item cannot be supplied in the requested quantity."""


class Inventory:
    def __init__(self, stock=None):
        self._stock = dict(stock or {})

    def available(self, sku):
        return self._stock.get(sku, 0)

    def add(self, sku, qty):
        if qty <= 0:
            raise ValueError("qty must be positive")
        self._stock[sku] = self._stock.get(sku, 0) + qty

    def remove(self, sku, qty):
        if qty <= 0:
            raise ValueError("qty must be positive")
        if self._stock.get(sku, 0) < qty:
            raise OutOfStock(sku)
        self._stock[sku] -= qty
