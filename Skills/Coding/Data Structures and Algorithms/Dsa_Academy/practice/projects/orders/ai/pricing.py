"""Price calculations. All money is in integer cents."""

BULK_QTY = 10
BULK_DISCOUNT = 0.10


def line_total(unit_price_cents, qty):
    """Price of one order line, with 10% off bulk lines."""
    total = unit_price_cents * qty
    if qty > BULK_QTY:
        total = int(total * (1 - BULK_DISCOUNT))
    return total
