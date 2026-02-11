#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage:"
  echo "  $0 <image> <result-dir> <loop> <test_script> \\"
  echo "     -cl <core_list...> [-e <docker|podman>]"
  echo
  echo "Examples:"
  echo "  $0 rt_test ./results 100000 rt_test.sh -cl 3"
  echo "  $0 rt_test ./results 100000 rt_test.sh -cl 0 1 2 3 -e podman"
  exit 1
}

# ---- 최소 인자 수 ----
if [ $# -lt 4 ]; then
  usage
fi

POSITIONAL_ARGS=()
CORES=()
ENGINE=podman

# ---- argument parsing ----
while [[ $# -gt 0 ]]; do
  case "$1" in
    -cl|--core-list)
      shift
      while [[ $# -gt 0 && "$1" != -* ]]; do
        CORES+=("$1")
        shift
      done
      ;;
    -e|--engine)
      ENGINE="$2"
      shift 2
      ;;
    -*)
      echo "ERROR: Unknown option $1"
      usage
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

# ---- positional args ----
if [ ${#POSITIONAL_ARGS[@]} -lt 4 ]; then
  echo "ERROR: Not enough positional arguments."
  usage
fi

IMAGE="${POSITIONAL_ARGS[0]}"
RESULT_DIR="${POSITIONAL_ARGS[1]}"
LOOP="${POSITIONAL_ARGS[2]}"
TEST_SCRIPT="${POSITIONAL_ARGS[3]}"

# ---- validation ----
if [ ${#CORES[@]} -eq 0 ]; then
  echo "ERROR: core list (-cl) must be specified."
  exit 1
fi

if [[ "${ENGINE}" != "docker" && "${ENGINE}" != "podman" ]]; then
  echo "ERROR: Invalid engine '${ENGINE}' (use docker or podman)"
  exit 1
fi

# ---- paths ----
get_abs() { readlink -m "$1"; }

SCRIPT_DIR=$(dirname "$0")
RESULT_DIR="$(get_abs "${RESULT_DIR}")"
ENTRY_PATH="$(get_abs "${SCRIPT_DIR}"/entry)"

if [ ! -f "${ENTRY_PATH}/${TEST_SCRIPT}" ]; then
  echo "ERROR: test script not found: ${ENTRY_PATH}/${TEST_SCRIPT}"
  exit 1
fi

mkdir -p "${RESULT_DIR}"

NOW="$(date +'%Y-%m-%d_%H%M%S')"
CONTAINER_NAME="rt_test_${NOW}"

# ---- engine specific ----
RUN_CMD="${ENGINE} run"

COMMON_OPTS=(
  --rm
  -it
  --name "${CONTAINER_NAME}"
  --privileged
  --network host
  --pid host
  --ipc host
)

if [ "${ENGINE}" = "podman" ]; then
  COMMON_OPTS+=(--userns=host)
#  RESULT_DIR_PERMISSION="rw"
#else
#  RESULT_DIR_PERMISSION=""
fi

# ---- info ----
echo "=========================================="
echo " Engine      : ${ENGINE}"
echo " Image       : ${IMAGE}"
echo " Result dir  : ${RESULT_DIR}"
echo " Loop        : ${LOOP}"
echo " Test script : ${TEST_SCRIPT}"
echo " Cores       : ${CORES[*]}"
echo "=========================================="

# ---- run container ----
${RUN_CMD} \
  "${COMMON_OPTS[@]}" \
  -v "${RESULT_DIR}:/results" \
  -v "${ENTRY_PATH}:/entry" \
  --device /dev/cpu_dma_latency \
  -v /dev:/dev \
  "${IMAGE}" \
  "/entry/${TEST_SCRIPT}" \
  /results \
  "${LOOP}" \
  "${CORES[@]}"

echo
echo "RT test completed."
echo "Results saved under: ${RESULT_DIR}"

