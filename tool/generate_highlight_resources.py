#!/usr/bin/env python3
"""Generate offline data URIs from pinned, hash-verified highlight.js resources.

2026-10-24 FPR-111: never fetch at generation/build/runtime. The original JS
contains </script>, so raw inline script interpolation would corrupt the HTML.
"""
import base64
import hashlib
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
VENDOR = ROOT / 'vendor/highlight.js/9.12.0'
OUTPUT = ROOT / 'lib/common/utils/highlight_resources.g.dart'


def generate():
    manifest = json.loads((VENDOR / 'provenance.json').read_text())
    resources = {}
    for item in manifest['files']:
        data = (VENDOR / item['path']).read_bytes()
        if len(data) != item['bytes'] or hashlib.sha256(data).hexdigest() != item['sha256']:
            raise ValueError('Vendored resource differs from pinned provenance: ' + item['path'])
        resources[item['path']] = data
    lines = [
        '// GENERATED CODE - DO NOT MODIFY BY HAND.',
        '// Run: python3 tool/generate_highlight_resources.py',
        '// 2026-10-24 FPR-111: offline 9.12.0 resources; source/license/hashes:',
        '// vendor/highlight.js/9.12.0/{README.md,LICENSE,provenance.json}.',
        '',
        'abstract final class HighlightResources {',
    ]
    for name, path, mime in [
        ('highlightJs', 'highlight.min.js', 'text/javascript'),
        ('goJs', 'languages/go.min.js', 'text/javascript'),
        ('githubCss', 'styles/github.min.css', 'text/css'),
        ('atomOneDarkCss', 'styles/atom-one-dark.min.css', 'text/css'),
    ]:
        uri = 'data:' + mime + ';base64,' + base64.b64encode(resources[path]).decode('ascii')
        lines.append('  static const ' + name + ' =')
        for offset in range(0, len(uri), 100):
            lines.append("      '" + uri[offset:offset + 100] + "'" + (';' if offset + 100 >= len(uri) else ''))
        lines.append('')
    # Preserve the complete notice inside every generated document, including
    # binary distributions: no external license URL is needed to read it.
    lines += ["  static const license = r'''" + resources['LICENSE'].decode('utf-8') + "''';", '}']
    return '\n'.join(lines) + '\n'


expected = generate()
if '--check' in sys.argv:
    if not OUTPUT.is_file() or OUTPUT.read_text() != expected:
        raise SystemExit('Generated highlight resources are stale')
else:
    OUTPUT.write_text(expected)
