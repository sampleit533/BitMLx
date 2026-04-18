#!/usr/bin/env bash
set -euo pipefail

IMAGE="${IMAGE:-blockchain-bitmlx:dev}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ensure_volume_ownership() {
  local vol="$1"
  docker volume create "${vol}" >/dev/null
  # Named volumes are root-owned by default; make them writable for uid/gid 1000.
  docker run --rm -v "${vol}:/v" alpine:3.19 sh -c "chown -R 1000:1000 /v" >/dev/null
}

ensure_volume_ownership blockchain_bitmlx_local
ensure_volume_ownership blockchain_bitmlx_stack

docker run --rm -t \
  -u 1000:1000 \
  -e HOME=/home/user \
  -v "${ROOT}:/workspace" \
  -v blockchain_bitmlx_local:/home/user/.local \
  -v blockchain_bitmlx_stack:/home/user/.stack \
  -w /workspace \
  "${IMAGE}" \
  bash -lc "$*"
