from pathlib import Path
import re
import sys

SKIP_DIRS = ('.git', 'vendor', 'build', 'generated', '__pycache__', '.pytest_cache')
PATTERNS = [
    r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----',
    # GitHub tokens: classic ghp/gho/ghu/ghs/ghr forms and the stateless
    # installation-token form (ghs_<appid>_<jwt>, JWT parts are URL-safe
    # and dot-separated, total length >500).
    r'gh[pousr]_[A-Za-z0-9_-]{20,}(?:\.[A-Za-z0-9_-]+)*',
    r'AKIA[A-Z0-9]{16}',
    r'https?://(?:localhost|127\.0\.0\.1|192\.168\.)',
]


def scan(root):
    bad = []
    for p in root.rglob('*'):
        if not p.is_file() or any(x in p.parts for x in SKIP_DIRS):
            continue
        text = p.read_text(errors='ignore')
        if any(re.search(x, text) for x in PATTERNS):
            bad.append(str(p.relative_to(root)))
    return bad


def main():
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[1]
    bad = scan(root)
    if bad:
        # File names only - never the matched content.
        raise SystemExit('Repository safety check failed: ' + ', '.join(bad))
    print('Repository safety patterns passed. Human review still required.')


if __name__ == '__main__':
    main()
