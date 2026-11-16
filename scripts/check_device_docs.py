"""Checks docs/DEVICE_TESTING.md: honesty status, Hebrew/English parity, project match."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
HE_VERIFIED = 'מאומת'
HE_UNVERIFIED = 'לא מאומת'
HE_NOT_RUN = 'לא הורץ על מכשיר'
EN_NOT_RUN = 'not run on a device'
# Rows that must be unverified in both languages: nothing ran on a device or Mac.
HE_MUST_UNVERIFIED = ('iPhone 6s עם iOS 15', 'Personal Team עובדת')
EN_MUST_UNVERIFIED = ('iPhone 6s with iOS 15', 'Personal Team signing works')


def split_sections(doc):
    m = re.search(r'^## עברית\s*$', doc, re.M)
    e = re.search(r'^## English\s*$', doc, re.M)
    if not m or not e or e.start() < m.start():
        return None, None
    return doc[m.end():e.start()], doc[e.end():]


def rows(section):
    return [r for r in section.splitlines() if r.startswith('|') and '---' not in r]


def status_of(row, he):
    cell = row.strip('|').split('|')[-1].strip()
    if he:
        if cell.startswith(HE_UNVERIFIED):
            return 'unverified'
        return 'verified' if cell.startswith(HE_VERIFIED) else None
    low = cell.lower()
    if low.startswith('unverified'):
        return 'unverified'
    return 'verified' if low.startswith('verified') else None


def problems(root=ROOT, doc=None, proj=None):
    out = []
    if doc is None:
        doc = (root / 'docs/DEVICE_TESTING.md').read_text(encoding='utf-8')
    if proj is None:
        proj = (root / 'project.yml').read_text(encoding='utf-8')
    he, en = split_sections(doc)
    if he is None:
        return ['Hebrew and English sections are missing or out of order']
    if not re.search(r'[\u0590-\u05FF]', he):
        out.append('Hebrew section has no Hebrew text')
    if HE_NOT_RUN not in he:
        out.append('Hebrew section lacks the "not run on a device" status')
    if EN_NOT_RUN not in en.lower():
        out.append('English section lacks the "not run on a device" status')
    status = {}
    for name, sec, he_flag, musts in (('he', he, True, HE_MUST_UNVERIFIED),
                                      ('en', en, False, EN_MUST_UNVERIFIED)):
        table = [(r, status_of(r, he_flag)) for r in rows(sec)]
        table = [(r, s) for r, s in table if s]
        status[name] = [s for _, s in table]
        for must in musts:
            hit = [s for r, s in table if must in r]
            if len(hit) != 1:
                out.append('%s: status row not found exactly once: %s' % (name, must))
            elif hit[0] != 'unverified':
                out.append('%s: row must be unverified: %s' % (name, must))
    if status['he'] != status['en']:
        out.append('Hebrew and English status tables differ')
    if len(status['en']) < 6:
        out.append('status table too short')
    for name, sec in (('he', he), ('en', en)):
        steps = re.findall(r'^\d+\. ', sec, re.M)
        if len(steps) < 16:
            out.append('%s: too few numbered steps' % name)
        for term in ('xcodegen generate', 'Personal Team', 'Developer Mode',
                     'Add Platforms', 'Connect via network', 'COMPATIBILITY.md'):
            if term not in sec:
                out.append('%s: missing term %s' % (name, term))
    m = re.search(r"IPHONEOS_DEPLOYMENT_TARGET:\s*'?([0-9.]+)", proj)
    if not m or m.group(1) != '15.0':
        out.append('project.yml deployment target is not 15.0')
    if re.search(r'gh[pousr]_[A-Za-z0-9_]{20,}', doc):
        out.append('token-like text')
    return out


if __name__ == '__main__':
    bad = problems()
    if bad:
        raise SystemExit('Device docs check failed: ' + '; '.join(bad))
    print('Device docs check passed.')
