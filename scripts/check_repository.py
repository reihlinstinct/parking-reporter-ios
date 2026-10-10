from pathlib import Path
import re
root = Path(__file__).resolve().parents[1]
bad = []
for p in root.rglob('*'):
    if not p.is_file() or any(x in p.parts for x in ('.git', 'vendor', 'build', 'generated')):
        continue
    text = p.read_text(errors='ignore')
    patterns = [r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----', r'gh[pousr]_[A-Za-z0-9]{20,}', r'AKIA[A-Z0-9]{16}', r'https?://(?:localhost|127\.0\.0\.1|192\.168\.)']
    if any(re.search(x, text) for x in patterns): bad.append(str(p.relative_to(root)))
if bad: raise SystemExit('Repository safety check failed: ' + ', '.join(bad))
print('Repository safety patterns passed. Human review still required.')
