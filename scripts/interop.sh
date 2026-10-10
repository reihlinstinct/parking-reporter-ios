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
mkdir -p "$ROOT/interop/generated"
javac -cp "$CP" -d "$ROOT/interop/generated" "$ROOT/interop/Generate.java"
java -cp "$ROOT/interop/generated:$CP" Generate "$ROOT/interop/generated"
mkdir -p "$ROOT/vendor/tink-objc/interop/generated"
cp "$ROOT/interop/InteropTests.m" "$ROOT/interop/BUILD.bazel" "$ROOT/vendor/tink-objc/interop/"
cp "$ROOT/interop/generated/"*.bin "$ROOT/vendor/tink-objc/interop/generated/"
cd "$ROOT/vendor/tink-objc"
bazel test //interop:interop_test --test_output=errors --ios_simulator_device="${SIM_DEVICE:-iPhone 16}" --ios_simulator_version="${SIM_VERSION:-18.5}"
