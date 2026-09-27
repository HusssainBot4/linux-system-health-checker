#!/usr/bin/env bash

set -u

SCRIPT="./bin/health-check.sh"

echo "Running syntax check..."
bash -n "$SCRIPT"

echo "Running help check..."
"$SCRIPT" --help >/dev/null

echo "Running invalid-option check..."
if "$SCRIPT" --invalid-option >/dev/null 2>&1; then
echo "FAIL: invalid option returned success"
exit 1
fi

echo "Running health check..."
set +e
"$SCRIPT" >/dev/null
rc=$?
set -e

if (( rc < 0 || rc > 3 )); then
echo "FAIL: unexpected exit code: $rc"
exit 1
fi

echo "PASS: health checker returned expected exit-code range: $rc"
echo "All tests passed."
