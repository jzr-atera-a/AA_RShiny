"""Parse access-log lines such as:

    2024-05-01T10:00:00 alice GET /home 200
"""


def parse_line(line):
    """Return a dict for a valid line, or None for a malformed one."""
    parts = line.strip().split(" ")
    if len(parts) != 5:
        return None
    ts, user, method, path, status = parts
    if not status.isdigit():
        return None
    return {"ts": ts, "user": user, "method": method, "path": path, "status": int(status)}
