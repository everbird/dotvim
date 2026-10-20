"""A tiny stdio LSP peer for the editor integration smoke test."""
import json
import os
from pathlib import Path
import sys


while True:
    headers = {}
    while True:
        line = sys.stdin.buffer.readline()
        if not line:
            sys.exit(0)
        if line == b'\r\n':
            break
        key, value = line.decode().split(':', 1)
        headers[key.lower()] = value.strip()
    message = json.loads(sys.stdin.buffer.read(int(headers['content-length'])))
    method = message.get('method', '')
    with Path(os.environ['DOTVIM_LSP_LOG']).open('a') as log:
        log.write(method + '\n')
    if method == 'exit':
        break
    if 'id' in message:
        result = None
        if method == 'initialize':
            result = {'capabilities': {'textDocumentSync': 1, 'definitionProvider': True,
                                       'completionProvider': {'triggerCharacters': ['.']}}}
        response = json.dumps({'jsonrpc': '2.0', 'id': message['id'], 'result': result}).encode()
        sys.stdout.buffer.write(('Content-Length: ' + str(len(response)) + '\r\n\r\n').encode() + response)
        sys.stdout.buffer.flush()
