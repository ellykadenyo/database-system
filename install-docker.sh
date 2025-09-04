#!/usr/bin/env bash
# Author: Elly Kadenyo
# Date: 2025-09-01 2025-09-04
# Description: Install latest Docker Engine + Docker Compose (plugin) on Ubuntu Linux. Also installs common utilities to avoid piecemeal setup.
# Reference: https://docs.docker.com/engine/install/ubuntu/
# Reference: https://docs.docker.com/compose/install/linux/
# Usage: bash install-docker.sh

set -euo pipefail

#----- sanity checks -----
if [[ ! -f /etc/os-release ]]; then
  echo "This script is intended for Ubuntu." >&2
  exit 1
fi
. /etc/os-release
if [[ "${ID:-}" != "ubuntu" ]]; then
  echo "Detected non-Ubuntu system (${ID:-unknown}). Aborting." >&2
  exit 1
fi

echo ">>> Updating apt and installing prerequisites..."
sudo apt-get update -y
sudo apt-get install -y \
  ca-certificates curl gnupg lsb-release apt-transport-https software-properties-common \
  git unzip jq build-essential make \
  vim htop wget

echo ">>> Removing any old Docker packages (safe to ignore if not present)..."
sudo apt-get remove -y docker docker-engine docker.io containerd runc || true

echo ">>> Setting up Docker’s official APT repository..."
sudo install -m 0755 -d /etc/apt/keyrings
if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
fi
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

echo ">>> Installing Docker Engine, CLI, containerd, Buildx, and Compose plugin..."
sudo apt-get update -y
sudo apt-get install -y \
  docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo ">>> Enabling and starting Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

echo ">>> Adding current user ($USER) to 'docker' group (for rootless use)..."
if ! getent group docker >/dev/null; then
  sudo groupadd docker
fi
sudo usermod -aG docker "$USER"

echo ">>> Versions:"
docker --version || true
docker compose version || true

cat <<'EONOTE'

Docker installation complete.

Notes:
- Use Docker Compose via:  docker compose up -d   (no hyphen; v2 plugin)
- You may need to **log out and back in** (or reboot) so your shell picks up new 'docker' group membership.
- If you want to test immediately in the current shell, run:  newgrp docker

EONOTE
