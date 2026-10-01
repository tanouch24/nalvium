from collections import defaultdict, deque
from time import monotonic

class RateLimiter:
    def __init__(self, limit: int = 12, window_seconds: int = 60):
        self.limit = limit
        self.window = window_seconds
        self.events: dict[str, deque[float]] = defaultdict(deque)

    def allow(self, key: str) -> bool:
        now = monotonic()
        queue = self.events[key]
        while queue and now - queue[0] >= self.window:
            queue.popleft()
        if len(queue) >= self.limit:
            return False
        queue.append(now)
        return True
