"""Minimal in-memory Google Drive v3 + OAuth stand-in for drive_check.dart. Usage: python3 fake_drive.py PORT"""
import base64, json, re, sys, threading, uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlsplit, parse_qs

lock = threading.Lock()
files = {}  # id -> dict(name, mimeType, parents, appProperties, content, driveId, description)
tokens = {'valid': set(), 'issued': 0}
state = {'device_polls': 0, 'fail_next_upload_500': 0, 'expire_next': 0, 'quota_error': False, 'log': []}
FOLDER = 'application/vnd.google-apps.folder'
files['sharedFolder01'] = dict(name='Team Shared Folder', mimeType=FOLDER, parents=[], appProperties={}, content=b'', driveId='drv1', description='')
files['plainfile'] = dict(name='not a folder.txt', mimeType='text/plain', parents=[], appProperties={}, content=b'x', driveId=None, description='')


def meta(fid):
    f = files[fid]
    return {'id': fid, 'name': f['name'], 'mimeType': f['mimeType'], 'size': str(len(f['content'])), 'webViewLink': f'https://drive.example/{fid}', 'modifiedTime': '2026-11-24T00:00:00Z',
            'driveId': f['driveId'], 'trashed': False, 'capabilities': {'canAddChildren': True}, 'parents': f['parents'], 'appProperties': f['appProperties']}


def unq(s):
    return s.replace("\\'", "'").replace('\\\\', '\\')


class H(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def send(self, code, body=b'', ctype='application/json', headers=None):
        if isinstance(body, (dict, list)):
            body = json.dumps(body).encode()
        self.send_response(code)
        self.send_header('Content-Type', ctype)
        self.send_header('Content-Length', str(len(body)))
        for k, v in (headers or {}).items():
            self.send_header(k, v)
        self.end_headers()
        self.wfile.write(body)

    def err(self, code, reason, msg):
        self.send(code, {'error': {'code': code, 'message': msg, 'errors': [{'reason': reason, 'message': msg}]}})

    def body(self):
        n = int(self.headers.get('Content-Length') or 0)
        return self.rfile.read(n) if n else b''

    def authed(self):
        a = self.headers.get('Authorization', '')
        tok = a[7:] if a.startswith('Bearer ') else ''
        with lock:
            if state['expire_next'] and tok in tokens['valid']:
                state['expire_next'] -= 1
                tokens['valid'].discard(tok)
            ok = tok in tokens['valid']
        if not ok:
            self.err(401, 'authError', 'Invalid Credentials')
        return ok

    def route(self, method):
        u = urlsplit(self.path)
        q = {k: v[0] for k, v in parse_qs(u.query).items()}
        p = u.path
        raw = self.body()
        with lock:
            state['log'].append({'method': method, 'path': p, 'q': q, 'auth': self.headers.get('Authorization', '')})
        # ---- OAuth
        if p == '/token' and method == 'POST':
            f = {k: v[0] for k, v in parse_qs(raw.decode()).items()}
            g = f.get('grant_type')
            if g == 'refresh_token':
                if f.get('refresh_token') == 'revoked':
                    return self.send(400, {'error': 'invalid_grant', 'error_description': 'Token has been expired or revoked.'})
                if f.get('client_id') != 'cid' or f.get('refresh_token') not in ('rt-good', 'rt-device'):
                    return self.send(401, {'error': 'invalid_client', 'error_description': 'bad client'})
            elif g == 'urn:ietf:params:oauth:grant-type:device_code':
                state['device_polls'] += 1
                n = state['device_polls']
                if f.get('device_code') == 'dev-deny':
                    return self.send(428, {'error': 'access_denied'})
                if n == 1:
                    return self.send(428, {'error': 'authorization_pending'})
                if n == 2:
                    return self.send(428, {'error': 'slow_down'})
                idt = 'x.' + base64.urlsafe_b64encode(json.dumps({'email': 'person@example.com'}).encode()).decode().rstrip('=') + '.y'
                with lock:
                    tokens['issued'] += 1
                    t = f"tok{tokens['issued']}"
                    tokens['valid'].add(t)
                return self.send(200, {'access_token': t, 'expires_in': 3600, 'refresh_token': 'rt-device', 'id_token': idt})
            elif g == 'urn:ietf:params:oauth:grant-type:jwt-bearer':
                pass
            else:
                return self.send(400, {'error': 'unsupported_grant_type'})
            with lock:
                tokens['issued'] += 1
                t = f"tok{tokens['issued']}"
                tokens['valid'].add(t)
            return self.send(200, {'access_token': t, 'expires_in': 3600})
        if p == '/device/code' and method == 'POST':
            f = {k: v[0] for k, v in parse_qs(raw.decode()).items()}
            if 'drive.file' not in f.get('scope', ''):
                return self.send(400, {'error': 'invalid_scope'})
            return self.send(200, {'device_code': 'dev-1', 'user_code': 'ABCD-EFGH', 'verification_url': 'https://www.google.com/device', 'expires_in': 600, 'interval': 1})
        if not self.authed():
            return
        # ---- Drive
        if p == '/drive/v3/about':
            return self.send(200, {'user': {'displayName': 'Test Person', 'emailAddress': 'person@example.com'}, 'storageQuota': {'limit': str(15 * 2**30), 'usage': str(2**30)}})
        m = re.fullmatch(r'/drive/v3/files/([^/]+)', p)
        if m and method == 'GET':
            fid = m.group(1)
            if fid not in files:
                return self.err(404, 'notFound', f'File not found: {fid}.')
            if q.get('alt') == 'media':
                return self.send(200, files[fid]['content'], files[fid]['mimeType'])
            return self.send(200, meta(fid))
        if m and method == 'DELETE':
            files.pop(m.group(1), None)
            return self.send(204)
        if p == '/drive/v3/files' and method == 'GET':
            qq = q.get('q', '')
            name = re.search(r"name = '((?:\\.|[^'])*)'", qq)
            parent = re.search(r"'((?:\\.|[^'])*)' in parents", qq)
            want_folder = FOLDER in qq
            props = re.findall(r"appProperties has \{ key='((?:\\.|[^'])*)' and value='((?:\\.|[^'])*)' \}", qq)
            res = []
            for fid, f in files.items():
                if name and f['name'] != unq(name.group(1)):
                    continue
                if parent and unq(parent.group(1)) not in f['parents']:
                    continue
                if want_folder and f['mimeType'] != FOLDER:
                    continue
                if any((f.get('appProperties') or {}).get(unq(k)) != unq(v) for k, v in props):
                    continue
                res.append(meta(fid))
            return self.send(200, {'files': res})
        if p == '/drive/v3/files' and method == 'POST':
            j = json.loads(raw)
            fid = 'f' + uuid.uuid4().hex[:10]
            parent = (j.get('parents') or ['root'])[0]
            drv = files[parent]['driveId'] if parent in files else None
            with lock:
                files[fid] = dict(name=j['name'], mimeType=j.get('mimeType', 'application/octet-stream'), parents=[parent], appProperties=j.get('appProperties', {}), content=b'', driveId=drv, description='')
            return self.send(200, {'id': fid})
        if p == '/upload/drive/v3/files' and method == 'POST':
            if state['fail_next_upload_500']:
                state['fail_next_upload_500'] -= 1
                return self.err(503, 'backendError', 'Backend Error')
            if state['quota_error']:
                return self.err(403, 'storageQuotaExceeded', 'Service Accounts do not have storage quota.')
            if q.get('uploadType') == 'multipart':
                ct = self.headers.get('Content-Type', '')
                b = re.search(r'boundary=(.+)$', ct).group(1).encode()
                parts = raw.split(b'--' + b)
                jpart = parts[1].split(b'\r\n\r\n', 1)[1].rstrip(b'\r\n')
                cpart = parts[2].split(b'\r\n\r\n', 1)[1]
                assert cpart.endswith(b'\r\n')
                return self.create(json.loads(jpart), cpart[:-2])
            if q.get('uploadType') == 'resumable':
                sid = uuid.uuid4().hex
                state['session_' + sid] = json.loads(raw)
                state['resumable_starts'] = state.get('resumable_starts', 0) + 1
                return self.send(200, b'', headers={'Location': f'http://127.0.0.1:{PORT}/upload/session/{sid}'})
        m = re.fullmatch(r'/upload/session/([0-9a-f]+)', p)
        if m and method == 'PUT':
            return self.create(state.pop('session_' + m.group(1)), raw)
        m = re.fullmatch(r'/upload/drive/v3/files/([^/]+)', p)
        if m and method == 'PATCH':
            fid = m.group(1)
            if fid not in files:
                return self.err(404, 'notFound', f'File not found: {fid}.')
            if q.get('uploadType') == 'multipart':   # metadata + content (CollaborationPlanning replaces files this way)
                ct = self.headers.get('Content-Type', '')
                b = re.search(r'boundary=(.+)$', ct).group(1).encode()
                parts = raw.split(b'--' + b)
                j = json.loads(parts[1].split(b'\r\n\r\n', 1)[1].rstrip(b'\r\n'))
                c = parts[2].split(b'\r\n\r\n', 1)[1]
                files[fid]['content'] = c[:-2] if c.endswith(b'\r\n') else c
                for k in ('name', 'mimeType'):
                    if k in j: files[fid][k] = j[k]
                if 'appProperties' in j: files[fid]['appProperties'] = j['appProperties']
            else:
                files[fid]['content'] = raw
            return self.send(200, {'id': fid})
        if p == '/_state':
            return self.send(200, {'files': {k: {**v, 'content': base64.b64encode(v['content']).decode()} for k, v in files.items()}, 'log': state['log'], 'tokens_issued': tokens['issued'],
                                   'resumable_starts': state.get('resumable_starts', 0)})
        self.err(404, 'notFound', 'no route ' + p)

    def create(self, j, content):
        fid = 'u' + uuid.uuid4().hex[:10]
        parent = (j.get('parents') or ['root'])[0]
        if parent != 'root' and parent not in files:
            return self.err(404, 'notFound', f'File not found: {parent}.')
        with lock:
            files[fid] = dict(name=j['name'], mimeType=j.get('mimeType', ''), parents=[parent], appProperties=j.get('appProperties', {}), content=content,
                              driveId=files[parent]['driveId'] if parent in files else None, description=j.get('description', ''))
        return self.send(200, {'id': fid, 'name': j['name'], 'webViewLink': f'https://drive.example/{fid}', 'size': str(len(content)), 'mimeType': j.get('mimeType', '')})

    def do_GET(self): self.route('GET')
    def do_POST(self):
        u = urlsplit(self.path)
        if u.path == '/_control':
            j = json.loads(self.body())
            state.update(j)
            return self.send(200, {'ok': True})
        self.route('POST')
    def do_PUT(self): self.route('PUT')
    def do_PATCH(self): self.route('PATCH')
    def do_DELETE(self): self.route('DELETE')


PORT = int(sys.argv[1])
ThreadingHTTPServer(('127.0.0.1', PORT), H).serve_forever()
