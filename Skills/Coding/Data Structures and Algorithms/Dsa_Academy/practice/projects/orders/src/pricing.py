"""Price calculations. All money is in integer cents."""


def line_total(unit_price_cents, qty):
    """Price of one order line."""
    return unit_price_cents * qty
