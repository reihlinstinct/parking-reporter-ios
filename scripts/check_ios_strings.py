"""Fail when a UI string used with language.text(he, en) lacks fr/ar/ru/am in ui_strings.json,
or when the shared table lacks he/en/fr for any key."""
import glob, json, re, sys
root = __import__('pathlib').Path(__file__).resolve().parents[1]
ui = json.load(open(root / 'Resources/i18n/ui_strings.json'))['strings']
shared = json.load(open(root / 'Resources/i18n/strings.json'))['strings']
pattern = re.compile(r'text\(\s*(?:[^"()]*\?\s*)?"((?:[^"\\]|\\.)*)"\s*(?::\s*"(?:[^"\\]|\\.)*"\s*)?,\s*(?:[^"()]*\?\s*)?"((?:[^"\\]|\\.)*)"(?:\s*:\s*"((?:[^"\\]|\\.)*)")?')
english = set()
for f in glob.glob(str(root / 'Sources/*.swift')):
    for m in pattern.finditer(open(f, encoding='utf-8').read()):
        english.update(g for g in (m.group(2), m.group(3)) if g)
bad = []
for e in sorted(english):
    entry = ui.get(e)
    missing = [l for l in ('fr', 'ar', 'ru', 'am') if not entry or not entry.get(l)]
    if missing: bad.append('%r missing %s' % (e, ','.join(missing)))
for k, v in shared.items():
    miss = [l for l in ('he', 'en', 'fr') if l not in v]
    if miss: bad.append('shared key %s missing %s' % (k, ','.join(miss)))
for e in ui:
    if e not in english: bad.append('unused catalog entry %r' % e)
if bad:
    print('\n'.join(bad)); sys.exit(1)
print('iOS strings complete: %d UI strings, %d shared keys' % (len(english), len(shared)))
