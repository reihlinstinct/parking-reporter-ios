"""Mutation tests: the honesty checker must fail when the document is made dishonest."""
import unittest
from pathlib import Path
import check_device_docs as c

ROOT = Path(__file__).resolve().parents[1]
DOC = (ROOT / 'docs/DEVICE_TESTING.md').read_text(encoding='utf-8')
PROJ = (ROOT / 'project.yml').read_text(encoding='utf-8')


def bad(doc, proj=PROJ):
    return c.problems(ROOT, doc, proj)


class Tests(unittest.TestCase):
    def test_real_doc_passes(self):
        self.assertEqual(bad(DOC), [])

    def test_drop_english_not_run_status(self):
        self.assertTrue(bad(DOC.replace('Status: not run on a device', 'Status: ok')))

    def test_drop_hebrew_not_run_status(self):
        self.assertTrue(bad(DOC.replace('לא הורץ על מכשיר', 'הורץ')))

    def test_flip_english_6s_row_to_verified(self):
        d = DOC.replace('iOS 15 | Unverified (needs a manual', 'iOS 15 | Verified (needs a manual')
        self.assertNotEqual(d, DOC)
        self.assertTrue(bad(d))

    def test_flip_hebrew_6s_row_to_verified(self):
        d = DOC.replace('iOS 15 | לא מאומת (דרושה', 'iOS 15 | מאומת (דרושה')
        self.assertNotEqual(d, DOC)
        self.assertTrue(bad(d))

    def test_flip_signing_row_to_verified(self):
        d = DOC.replace('Unverified (no Mac was available)', 'Verified (no Mac was available)')
        self.assertNotEqual(d, DOC)
        self.assertTrue(bad(d))

    def test_status_tables_must_match(self):
        d = DOC.replace('Verified (Apple Xcode help)', 'Unverified (Apple Xcode help)')
        self.assertNotEqual(d, DOC)
        self.assertTrue(bad(d))

    def test_missing_hebrew_signing_section(self):
        he_start = DOC.index('### שלבים')
        he_end = DOC.index('### Wi-Fi אחרי')
        self.assertTrue(bad(DOC[:he_start] + DOC[he_end:]))

    def test_wrong_deployment_target(self):
        self.assertTrue(bad(DOC, PROJ.replace("'15.0'", "'16.0'")))

    def test_missing_language_sections(self):
        self.assertTrue(bad(DOC.replace('## English', '## Other')))


if __name__ == '__main__':
    unittest.main()
