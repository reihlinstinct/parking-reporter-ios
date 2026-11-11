"""Checks docs/DEVICE_TESTING.md stays consistent with the project."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]


def problems(root=ROOT):
    out = []
    doc = (root / 'docs/DEVICE_TESTING.md').read_text(encoding='utf-8')
    proj = (root / 'project.yml').read_text(encoding='utf-8')
    if not re.search(r'[\u0590-\u05FF]', doc):
        out.append('no Hebrew text')
    for word in ('VERIFIED', 'UNVERIFIED', 'Personal Team', 'Developer Mode',
                 'xcodegen generate', 'Add Platforms', 'Connect via network'):
        if word not in doc:
            out.append('missing: ' + word)
    m = re.search(r"IPHONEOS_DEPLOYMENT_TARGET:\s*'?([0-9.]+)", proj)
    if not m or m.group(1) != '15.0':
        out.append('project.yml deployment target is not 15.0')
    if 'iOS 15' not in doc:
        out.append('doc does not mention iOS 15')
    numbered = re.findall(r'^\d+\. ', doc, re.M)
    if len(numbered) < 20:
        out.append('too few numbered steps')
    if re.search(r'gh[pousr]_[A-Za-z0-9_]{20,}', doc):
        out.append('token-like text')
    return out


if __name__ == '__main__':
    bad = problems()
    if bad:
        raise SystemExit('Device docs check failed: ' + '; '.join(bad))
    print('Device docs check passed.')
