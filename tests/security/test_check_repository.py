import importlib.util
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

P = Path(__file__).resolve().parents[2] / 'scripts/check_repository.py'
spec = importlib.util.spec_from_file_location('check_repository', P)
g = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = g
spec.loader.exec_module(g)

# Tokens are assembled, never literal, so this test file itself stays clean.
CLASSIC = 'ghs' + '_' + 'A' * 36
STATELESS = 'ghs' + '_12345_' + 'A' * 100 + '.' + 'B' * 300 + '.' + 'C' * 108
LONG_STATELESS = 'ghs' + '_12345_' + 'A' * 100 + '.' + 'B' * 300 + '.' + 'C' * 200


class ScanTests(unittest.TestCase):
    def scan_one(self, content):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            (root / 'f.txt').write_text(content)
            return g.scan(root)

    def test_classic_installation_token(self):
        self.assertEqual(self.scan_one('token: ' + CLASSIC), ['f.txt'])

    def test_stateless_installation_token(self):
        self.assertEqual(self.scan_one('token: ' + STATELESS), ['f.txt'])

    def test_over_520_char_stateless_token(self):
        self.assertEqual(self.scan_one('token: ' + LONG_STATELESS), ['f.txt'])

    def test_clean_file(self):
        self.assertEqual(self.scan_one('nothing secret here'), [])

    def test_skip_dirs_untouched(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            (root / 'build').mkdir()
            (root / 'build' / 'f.txt').write_text(CLASSIC)
            self.assertEqual(g.scan(root), [])

    def test_cli_names_files_only_not_contents(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            (root / 'leak.txt').write_text(STATELESS)
            result = subprocess.run(
                [sys.executable, str(P), d], capture_output=True, text=True
            )
            self.assertNotEqual(result.returncode, 0)
            output = result.stdout + result.stderr
            self.assertIn('leak.txt', output)
            self.assertNotIn(STATELESS, output)


if __name__ == '__main__':
    unittest.main()
