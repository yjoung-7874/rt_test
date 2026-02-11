#!/bin/bash

# usage
print_usage () {
  echo ""
  echo "Usage:"
  echo "  $0 <engine> <image-name> <dockerfile-path> <result-path> <loop> <test_script>"
  echo "Examples:"
  echo "  $0 docker rt_test path/to/dockerfile ~/rt/test/container/results 10000 rt_test.sh "
}

if [ $# -lt 6 ]; then
  print_usage
  exit 1
fi

ENGINE=$1
IMAGE_NAME=$2
DOCKERFILE_PATH=$3
RESULT_DIR=$4
LOOP=$5
TEST_SCRIPT=$6

bash ./scripts/env/env_build.sh -e ${ENGINE} ${IMAGE_NAME} ${DOCKERFILE_PATH}

bash ./scripts/test/test.sh ${IMAGE_NAME} ${RESULT_DIR} ${LOOP} ${TEST_SCRIPT} -e ${ENGINE} -cl 0 1 2 3
