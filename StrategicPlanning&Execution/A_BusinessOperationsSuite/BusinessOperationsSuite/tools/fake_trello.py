# tools/fake_trello.py - a tiny stand-in for the Trello REST API (boards/<id>/lists, boards/<id>/cards/all, cards POST/PUT)
# Run: python3 tools/fake_trello.py 8931   (state: one board "B" with lists To Do / Doing / Done and one CollaborationPlanning card)
import json, sys, urllib.parse
from http.server import BaseHTTPRequestHandler, HTTPServer
lists = [{"id": "L1", "name": "To Do"}, {"id": "L2", "name": "Doing"}, {"id": "L3", "name": "Done"}]
cards = {"CP1": {"id": "CP1", "name": "Design", "idList": "L1", "closed": False, "dueComplete": False, "url": "https://trello.com/c/CP1",
                 "shortUrl": "https://trello.com/c/CP1", "desc": "Owner: x\nFrom Collaboration Planning task tsk_1"}}
n = [0]
class H(BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def send(self, obj, code=200):
        b = json.dumps(obj).encode(); self.send_response(code); self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(b))); self.end_headers(); self.wfile.write(b)
    def parts(self):
        u = urllib.parse.urlparse(self.path); return u.path.split("/")[2:], dict(urllib.parse.parse_qsl(u.query))
    def do_GET(self):
        p, q = self.parts()
        if p[:1] == ["_state"]: return self.send(cards)
        if p[:1] == ["boards"] and p[2:] == ["lists"]: return self.send(lists)
        if p[:1] == ["boards"] and p[2:] == ["cards", "all"]: return self.send(list(cards.values()))
        self.send({"error": "no"}, 404)
    def do_POST(self):
        p, q = self.parts()
        if p == ["cards"]:
            n[0] += 1; cid = "C%d" % n[0]
            cards[cid] = {"id": cid, "name": q.get("name", ""), "idList": q.get("idList", ""), "closed": False, "dueComplete": False,
                          "url": "https://trello.com/c/" + cid, "shortUrl": "https://trello.com/c/" + cid, "desc": q.get("desc", ""), "due": q.get("due")}
            return self.send(cards[cid])
        if p[:1] == ["_move"]: cards[p[1]]["idList"] = p[2]; return self.send(cards[p[1]])
        self.send({"error": "no"}, 404)
    def do_PUT(self):
        p, q = self.parts()
        if p[:1] == ["cards"] and p[1] in cards:
            for k in ("name", "desc", "due"):
                if k in q: cards[p[1]][k] = q[k]
            return self.send(cards[p[1]])
        self.send("invalid id", 404)
HTTPServer(("127.0.0.1", int(sys.argv[1])), H).serve_forever()
