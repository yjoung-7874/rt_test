#!/usr/bin/env bash

set -e

# Install Podman if not installed
if ! command -v podman > /dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y \
    podman \
    uidmap \
    slirp4netns \
    fuse-overlayfs
fi

# Enable lingering for rootless containers
if ! loginctl show-user "$USER" | grep -q "Linger=yes"; then
  sudo loginctl enable-linger "$USER"
fi

# Ensure subuid/subgid mappings exist (required for rootless podman)
if ! grep -q "^$USER:" /etc/subuid; then
  echo "$USER:100000:65536" | sudo tee -a /etc/subuid
fi

if ! grep -q "^$USER:" /etc/subgid; then
  echo "$USER:100000:65536" | sudo tee -a /etc/subgid
fi

echo "Podman installation and rootless configuration complete."
echo "Please log out and log back in for changes to take effect."
