class FakeClock:
    """A clock you can move by hand in tests: pass clock=FakeClock() to TTLCache."""

    def __init__(self, t=0.0):
        self.t = t

    def __call__(self):
        return self.t

    def advance(self, seconds):
        self.t += seconds
