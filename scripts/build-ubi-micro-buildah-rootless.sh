#!/usr/bin/env bash
set -euo pipefail

# Rootless Buildah build helper
# Usage: scripts/build-ubi-micro-buildah-rootless.sh [image-tag] [Dockerfile]

TAG=${1:-languagetool:ubi-micro-jdk21}
DOCKERFILE=${2:-Dockerfile.ubibuild}

echo "Building image tag: $TAG using Dockerfile: $DOCKERFILE"

if ! command -v buildah >/dev/null 2>&1; then
  echo "ERROR: buildah not found. Install buildah (e.g., apt install buildah) or use podman." >&2
  exit 1
fi

# Try to detect LT_VER from Containerfile and pass it through to the build
LT_VER=""
if [[ -f Containerfile ]]; then
  LT_VER=$(sed -n -E 's|ARG LT_VER=(.*)$|\1|p' Containerfile || true)
fi

echo "Attempting rootless build with: buildah bud -f $DOCKERFILE -t $TAG (LT_VER=${LT_VER:-default})"
if [[ -n "${LT_VER}" ]]; then
  if buildah bud -f "$DOCKERFILE" --build-arg "LT_VER=$LT_VER" -t "$TAG" .; then
    echo "Build succeeded: $TAG"
    echo "Run to verify: podman run --rm -it $TAG java -version"
    exit 0
  fi
else
  if buildah bud -f "$DOCKERFILE" -t "$TAG" .; then
    echo "Build succeeded: $TAG"
    echo "Run to verify: podman run --rm -it $TAG java -version"
    exit 0
  fi
fi
  echo "Build succeeded: $TAG"
  echo "Run to verify: podman run --rm -it $TAG java -version"
  exit 0
fi

echo "buildah bud failed or returned non-zero. Falling back to installroot method (may require additional privileges)."

# Fallback: populate ubi-micro filesystem using buildah from + dnf --installroot
microcontainer=$(buildah from registry.access.redhat.com/ubi10/ubi-micro)
micromount=$(buildah mount "$microcontainer")

echo "Installing packages into mounted root ($micromount) via dnf --installroot"
dnf install --installroot "$micromount" --releasever 10 --setopt install_weak_deps=false --nodocs -y java-21-openjdk-headless
dnf clean all --installroot "$micromount" || true

buildah umount "$microcontainer"
buildah commit "$microcontainer" "$TAG"

echo "Committed image: $TAG"
echo "Run to verify: podman run --rm -it $TAG java -version"
