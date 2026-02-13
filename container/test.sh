#!/bin/bash

TEST_COUNT=$1
shift

if [[ -z "$TEST_COUNT" ]]; then
  echo "Example: $0 3 docker podman"
  exit 1
fi

if [[ $# -eq 0 ]]; then
  echo "Example: $0 3 docker podman"
  exit 1
fi

for ENGINE in "$@"; do
  echo "========================================"
  echo "Container engine: ${ENGINE}, Test count: ${TEST_COUNT}"
  echo "========================================"

  ./scripts/setup/${ENGINE}.sh

  for ((i=1; i<=TEST_COUNT; i++)); do
    echo "🔹 [${ENGINE}] ${i}/${TEST_COUNT} test in progress..."
     ./scripts/run.sh "$ENGINE" rt_test ./dockerfiles/rt_test ~/rt/test/container/results/"$ENGINE" 1000000 rt_test.sh 0 1 2 3

    if [[ $? -eq 0 ]]; then
      echo "[${ENGINE}] ${i} th test done"
    else
      echo "[${ENGINE}] ${i} th test failed"
    fi
    echo "----------------------------------------"
  done
done

echo "test completed"
