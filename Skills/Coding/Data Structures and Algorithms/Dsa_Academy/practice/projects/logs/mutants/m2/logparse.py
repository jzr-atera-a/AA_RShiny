def parse_line(line):
    parts = line.strip().split(" ")
    if len(parts) != 5:
        return None
    ts, user, method, path, status = parts
    if not status.isdigit():
        return None
    return {"ts": ts, "user": user, "method": method, "path": path, "status": int(status)}
