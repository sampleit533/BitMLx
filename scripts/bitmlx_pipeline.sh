#!/usr/bin/env bash
set -euo pipefail

EXAMPLE="${1:-all}"
PYTHON="/home/user/.local/venv/bin/python"

cd /workspace/vendor/BitMLx
mkdir -p output

# Make runs reproducible from a clean slate (avoid stale rkt/balzac from previous examples).
rm -f output/*.rkt output/*.balzac output/*_depth.txt output/statistics.txt || true

if [[ "${EXAMPLE}" == "all" ]]; then
  stack run
else
  stack run -- "${EXAMPLE}"
fi

shopt -s nullglob
for file_path in output/*.rkt; do
  ${PYTHON} replace_hash.py "${file_path}"
  racket "${file_path}" > "${file_path%.rkt}.balzac"
done

tmp_stats="$(mktemp)"
${PYTHON} read_statistics.py > "${tmp_stats}" || true
mv "${tmp_stats}" output/statistics.txt

echo "compiled: ${EXAMPLE}"
