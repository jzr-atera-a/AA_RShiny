import time
from collections import OrderedDict


class LRUCache:
    """Least-recently-used cache with O(1) get / put."""

    def __init__(self, capacity):
        if capacity <= 0:
            raise ValueError("capacity must be positive")
        self.capacity = capacity
        self.data = OrderedDict()

    def get(self, key):
        if key not in self.data:
            return -1
        self.data.move_to_end(key)
        return self.data[key]

    def put(self, key, value):
        if key in self.data:
            self.data.move_to_end(key)
        self.data[key] = value
        if len(self.data) > self.capacity:
            self.data.popitem(last=False)

    def __len__(self):
        return len(self.data)


class TTLCache(LRUCache):
    """LRU cache whose entries expire ttl seconds after they were last written."""

    def __init__(self, capacity, ttl, clock=time.monotonic):
        if ttl <= 0:
            raise ValueError("ttl must be positive")
        super().__init__(capacity)
        self.ttl = ttl
        self.clock = clock
        self.born = {}

    def _expired(self, key):
        return self.clock() - self.born[key] >= self.ttl

    def _drop(self, key):
        del self.data[key]
        del self.born[key]

    def _purge(self):
        # O(n); a heap keyed by expiry time makes this O(log n) amortised if needed
        for key in [k for k in self.data if self._expired(k)]:
            self._drop(key)

    def get(self, key):
        if key in self.data and self._expired(key):
            self._drop(key)
        return super().get(key)

    def put(self, key, value):
        self.born[key] = self.clock()
        if key in self.data:
            self.data.move_to_end(key)
        self.data[key] = value
        if len(self.data) > self.capacity:
            old, _ = self.data.popitem(last=False)
            del self.born[old]

    def __len__(self):
        self._purge()
        return len(self.data)
