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
    """LRU cache whose entries also expire (see the task)."""

    def __init__(self, capacity, ttl, clock=time.monotonic):
        raise NotImplementedError
