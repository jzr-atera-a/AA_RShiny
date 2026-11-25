BULK_QTY = 10


def line_total(unit_price_cents, qty):
    total = unit_price_cents * qty
    if qty >= BULK_QTY:
        total = -(-total * 9 // 10)
    return total
