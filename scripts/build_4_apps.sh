#!/usr/bin/env bash
set -euo pipefail

cd /workspace

apps=(
  ReceiverChosenDenomination
  TwoPartyAgreement
  MultichainPaymentExchange
  MultichainLoanMediator
)

out_root="/workspace/vendor/BitMLx/output"
dist_root="/workspace/dist/bitmlx_artifacts"

mkdir -p "${dist_root}"

for app in "${apps[@]}"; do
  ./scripts/bitmlx_pipeline.sh "${app}"

  d="${dist_root}/${app}"
  mkdir -p "${d}"

  cp -f "${out_root}/${app}_bitcoin.rkt" "${d}/"
  cp -f "${out_root}/${app}_dogecoin.rkt" "${d}/"
  cp -f "${out_root}/${app}_bitcoin.balzac" "${d}/"
  cp -f "${out_root}/${app}_dogecoin.balzac" "${d}/"
  cp -f "${out_root}/${app}_depth.txt" "${d}/"
  cp -f "${out_root}/statistics.txt" "${d}/"
done

echo "artifacts written to ${dist_root}"

