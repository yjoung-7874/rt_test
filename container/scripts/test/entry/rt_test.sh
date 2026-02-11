#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Usage: $0 <output_directory> <loop> [core_list]"
    exit 1
fi

OUTDIR="$1"
LOOP="$2"
shift 2

CORES=("$@")


TIMESTAMP=$(date +%Y%m%d_%H%M%S)
HISTO=100

mkdir -p "$OUTDIR"/"$TIMESTAMP"

EXPDIR="$OUTDIR"/"$TIMESTAMP"

echo "=== Cyclictest per-core test started at $TIMESTAMP ==="
echo "Output directory: $EXPDIR"
echo "Cores to test: ${CORES[*]}"

if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
else
  SUDO="sudo"
fi

for CORE in "${CORES[@]}"; do
    OUTFILE="${EXPDIR}/result_core${CORE}_${TIMESTAMP}.txt"
    echo "Running on CPU${CORE}..."
    ${SUDO} chrt -f 99 taskset -c ${CORE} cyclictest -t1 -p99 -m -x -l${LOOP} --histofall=${HISTO} \
                 --histfile=${OUTFILE}
done

declare -A max_core
for CORE in "${CORES[@]}"; do
    max_core[$CORE]=$(awk '/# Max Latencies:/ {print $4+0}' \
		    "${EXPDIR}/result_core${CORE}_${TIMESTAMP}.txt")
done

MAX_LAT=0
for CORE in "${CORES[@]}"; do
    if [ "${max_core[$CORE]}" -gt "$MAX_LAT" ]; then
        MAX_LAT="${max_core[$CORE]}"
    fi
done
XRANGE_MAX=$((MAX_LAT + 100))

PLOTFILE="${EXPDIR}/plot_${TIMESTAMP}.png"

gnuplot <<EOF
set title "Latency plot"
set terminal png size 1200,800
set output "${PLOTFILE}"
set xlabel "Latency (us)"
set logscale y
set xrange [0:${XRANGE_MAX}]
set yrange [0.8:*]
set ylabel "Number of latency samples"
set grid
set key outside
plot \
$(for CORE in "${CORES[@]}"; do
    echo "\"${EXPDIR}/result_core${CORE}_${TIMESTAMP}.txt\" using 1:2 with lines title \"CPU${CORE} (max ${max_core[$CORE]} us)\", \\"
done | sed '$ s/, \\$//')
EOF

echo "Plot saved to ${PLOTFILE}"
