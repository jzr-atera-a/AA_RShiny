"""Price calculations. All money is in integer cents."""

BULK_QTY = 10


def line_total(unit_price_cents, qty):
    """Price of one order line. Lines of BULK_QTY or more units get 10% off, rounded down."""
    total = unit_price_cents * qty
    if qty >= BULK_QTY:
        total = total * 9 // 10                   # integer maths: no float rounding surprises
    return total
