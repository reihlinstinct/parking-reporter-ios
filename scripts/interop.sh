#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PIN=72166ba925e693c4004d5099d2d31e10c655e216
mkdir -p "$ROOT/vendor"
if [ ! -d "$ROOT/vendor/tink-objc/.git" ]; then git clone https://github.com/tink-crypto/tink-objc "$ROOT/vendor/tink-objc"; fi
git -C "$ROOT/vendor/tink-objc" checkout --detach "$PIN"
test "$(git -C "$ROOT/vendor/tink-objc" rev-parse HEAD)" = "$PIN"
mvn -q -f "$ROOT/interop/pom.xml" dependency:build-classpath -Dmdep.outputFile="$ROOT/interop/classpath.txt"
CP="$(cat "$ROOT/interop/classpath.txt")"
# The Java side is only version-pinned in interop/pom.xml; verify the exact
# resolved jar bytes against the publisher checksum (repo1.maven.org,
# tink-1.23.0.jar, SHA256 verified 2026-11-01) before running any interop code.
JAR="$(tr ':' '\n' <<< "$CP" | grep '/tink/1.23.0/tink-1.23.0.jar$' || true)"
[ -n "$JAR" ] || { echo "tink-1.23.0.jar not found on the resolved classpath"; exit 1; }
echo "5bcdc8798ce106f5145acb4a0e993c5e5861337b1e75ca88ceb6ab9da10fa512  $JAR" | shasum -a 256 -c -
mkdir -p "$ROOT/interop/generated"
javac -encoding UTF-8 -cp "$CP" -d "$ROOT/interop/generated" "$ROOT/interop/Generate.java"
java -Dfile.encoding=UTF-8 -cp "$ROOT/interop/generated:$CP" Generate "$ROOT/interop/generated"
mkdir -p "$ROOT/vendor/tink-objc/interop/generated"
cp "$ROOT/interop/InteropTests.m" "$ROOT/interop/BUILD.bazel" "$ROOT/vendor/tink-objc/interop/"
cp "$ROOT/interop/generated/"*.bin "$ROOT/vendor/tink-objc/interop/generated/"
cd "$ROOT/vendor/tink-objc"
bazel test //interop:interop_test --test_output=all --ios_simulator_device="${SIM_DEVICE:-iPhone 16}" --ios_simulator_version="${SIM_VERSION:-18.5}" 2>&1 | tee "$ROOT/interop/generated/test.log"
python3 - "$ROOT/interop/generated/test.log" "$ROOT/interop/generated/objc-ciphertext.bin" <<'PY2'
import sys,re,base64
text=open(sys.argv[1]).read()
values=re.findall(r'REVERSE_VECTOR:([A-Za-z0-9+/=]+)',text)
if not values: raise SystemExit('Missing reverse-direction ciphertext; cannot claim compatibility')
open(sys.argv[2],'wb').write(base64.b64decode(values[-1],validate=True))
PY2
java -Dfile.encoding=UTF-8 -cp "$ROOT/interop/generated:$CP" Generate "$ROOT/interop/generated" "$ROOT/interop/generated"
