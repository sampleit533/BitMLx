#!/usr/bin/env bash
set -euo pipefail

IMAGE="${IMAGE:-blockchain-bitmlx:dev}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCKER_NETWORK="${DOCKER_NETWORK:-}"

if [[ -z "${DOCKER_NETWORK}" ]]; then
  if docker network inspect bridge >/dev/null 2>&1; then
    DOCKER_NETWORK="bridge"
  else
    # Some lab/VM Docker installations remove the default bridge network.
    # Host networking keeps the local reproducible pipeline usable there.
    DOCKER_NETWORK="host"
  fi
fi

ensure_volume_ownership() {
  local vol="$1"
  docker volume create "${vol}" >/dev/null
  # Named volumes are root-owned by default; make them writable for uid/gid 1000.
  docker run --rm --network="${DOCKER_NETWORK}" -v "${vol}:/v" alpine:3.19 sh -c "chown -R 1000:1000 /v" >/dev/null
}

ensure_volume_ownership blockchain_bitmlx_local
ensure_volume_ownership blockchain_bitmlx_stack

docker run --rm -t \
  --network="${DOCKER_NETWORK}" \
  -u 1000:1000 \
  -e HOME=/home/user \
  -v "${ROOT}:/workspace" \
  -v blockchain_bitmlx_local:/home/user/.local \
  -v blockchain_bitmlx_stack:/home/user/.stack \
  -w /workspace \
  "${IMAGE}" \
  bash -lc "$*"
