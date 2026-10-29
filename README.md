# parking-reporter-ios

[![signing-safety](https://github.com/reihlinstinct/parking-reporter-ios/actions/workflows/signing-safety.yml/badge.svg)](https://github.com/reihlinstinct/parking-reporter-ios/actions/workflows/signing-safety.yml)
Offline-first iOS 15 parking report review preview. No live submissions.

## CI

Every workflow ends with a `Run summary` job that writes a summary to the top of the run page: which jobs ran, their result and duration, what was skipped and why, the commits and files the run changed, and which checks cover those changes (`.github/ci-coverage-map.json` declares the coverage; files matching no mapping are flagged). The script is `scripts/ci/run_summary.py`.
