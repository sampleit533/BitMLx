#!/usr/bin/env bash
set -euo pipefail

cd /workspace

# Python deps for the BitMLx pipeline + tests (use venv; Debian blocks global/user pip by default).
VENV="/home/user/.local/venv"
if [[ ! -x "${VENV}/bin/python" ]]; then
  python3 -m venv "${VENV}"
fi
${VENV}/bin/pip install -q --upgrade pip
${VENV}/bin/pip install -q prettytable pytest

# Install BitML compiler as a local Racket package so `#lang bitml` works.
# Idempotent thanks to --skip-installed.
raco pkg install --auto --batch --skip-installed --no-docs /workspace/vendor/bitml-compiler >/dev/null

# Build BitMLx compiler (Haskell).
cd /workspace/vendor/BitMLx
stack setup >/dev/null
stack build >/dev/null

echo "bootstrap ok"
