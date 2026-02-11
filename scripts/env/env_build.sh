#!/usr/bin/env bash

set -o errexit

# usage
print_usage () {
  echo ""
  echo "Usage:"
  echo "  $0 [-h|--help] <image-name> <dockerfile-path>"
  echo "  $0 [-h|--help] [-e <docker/podman>] <image-name> <dockerfile-path>"
  echo "    e.g.,; $0 -e podman rt_test /path/to/dockerfile"
  echo "           TODO: $0 ubuntu_jammy /path/to/dockerfile"
  echo "           TODO: $0 -e podman ros2_humble /path/to/dockerfile"
  echo ""
  echo "  arguments:"
  echo "    image-name      : Dockerfile.{image-name}"
  echo "    dockerfile-path : path to dockerfile; <path-to-dockerfile>/Dockerfile.{image-name}"
  echo ""
  echo "  options:"
  echo "    -h, --help   : print usage"
  echo "    -e, --engine : container-engine; docker(Default) or podman"
  echo ""

  exit 0
}

echo -e "\033[32;1m IMAGE build started\033[0m"

SCRIPT_DIR=$(dirname $(realpath $0))
POSITIONAL_ARGS=()
CONTAINER_ENGINE=docker # Set default container engine

PLATFORMS="linux/amd64" # Default platforms
# PLATFORMS="linux/arm64/v8,linux/amd64" # Example for multi-arch

# Handle options
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -h|--help)
      print_usage
      ;;
    -e|--engine)
      shift
      CONTAINER_ENGINE="$1"
      shift
      ;;
    --platform)
      shift
      PLATFORMS="$1"
      shift
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

# DEBUGGING - check options
echo "Positional Arguments: ${POSITIONAL_ARGS[@]}"
echo "Platforms: $PLATFORMS"

if [ ${#POSITIONAL_ARGS[@]} -lt 2 ]; then
  echo "ERROR: Not enough arguments provided."
  print_usage 1
fi

if [[ -z "$PLATFORMS" ]]; then
  echo "No architecture specified. Using host architecture."
else
  echo "Building environment for platforms: $PLATFORMS"
fi

IMAGE_NAME="${POSITIONAL_ARGS[0]}"
DOCKERFILE_PATH="${POSITIONAL_ARGS[1]}"

tag_name="latest"
echo "Building image: $IMAGE_NAME with tag: $tag_name using $CONTAINER_ENGINE"

"$CONTAINER_ENGINE" build \
  -t "$IMAGE_NAME":"$tag_name" \
  -f "${DOCKERFILE_PATH}/Dockerfile.${IMAGE_NAME}" \
  "${DOCKERFILE_PATH}"

