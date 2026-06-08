#!/usr/bin/env bash
# Wall-clock benchmark for the BitMLx pipeline.
# Runs each example end-to-end (Haskell compile -> hash replace -> racket lower)
# with a fixed BITMLX_HASH_SEED so results are byte-deterministic and timings
# are not polluted by RNG variability.
#
# For each application a warmup run is performed (and discarded) to stabilise
# Stack's build cache, followed by REPEATS measured runs. The script reports
# per-run times plus the mean and sample standard deviation, so the paper can
# quote mean +/- std dev rather than a single observation.
#
# Output: human-readable summary on stdout, plus a CSV block. Per-run logs land
# in /tmp/bm_<App>_<run>.log.
set -euo pipefail

export BITMLX_HASH_SEED="${BITMLX_HASH_SEED:-42}"
REPEATS="${REPEATS:-5}"

APPS=(ReceiverChosenDenomination TwoPartyAgreement MultichainPaymentExchange MultichainLoanMediator)

cd /workspace

echo "# BitMLx compilation benchmark"
echo "# seed=${BITMLX_HASH_SEED} repeats=${REPEATS} (plus 1 discarded warmup per app)"
echo
echo "app,run,seconds"

# Collect "app mean std min max" rows for the final summary table.
summary=""

for EX in "${APPS[@]}"; do
  # Warmup (discarded): warms Stack and filesystem caches.
  ./scripts/bitmlx_pipeline.sh "$EX" > "/tmp/bm_${EX}_warmup.log" 2>&1

  times=()
  for run in $(seq 1 "${REPEATS}"); do
    start=$(date +%s.%N)
    ./scripts/bitmlx_pipeline.sh "$EX" > "/tmp/bm_${EX}_${run}.log" 2>&1
    end=$(date +%s.%N)
    elapsed=$(awk "BEGIN {printf \"%.3f\", $end - $start}")
    times+=("$elapsed")
    printf "%s,%s,%s\n" "$EX" "$run" "$elapsed"
  done

  stats=$(printf "%s\n" "${times[@]}" | awk '
    { x[NR]=$1; sum+=$1; if (NR==1||$1<min) min=$1; if (NR==1||$1>max) max=$1 }
    END {
      n=NR; mean=sum/n; ss=0;
      for (i=1;i<=n;i++) ss+=(x[i]-mean)*(x[i]-mean);
      sd=(n>1)?sqrt(ss/(n-1)):0;
      printf "%.3f %.3f %.3f %.3f", mean, sd, min, max
    }')
  summary+="${EX} ${stats}"$'\n'
done

echo
echo "# summary: app mean(s) stddev(s) min(s) max(s)"
printf "%s" "$summary" | awk '{ printf "%-32s %8s %8s %8s %8s\n", $1, $2, $3, $4, $5 }'
