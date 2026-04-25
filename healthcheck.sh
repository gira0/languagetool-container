#!/bin/bash
#--interval=2m --start-period=5m --timeout=5s CMD curl -f http://localhost:8080/v2/languages || exit 1

set -euo pipefail

# Determine image to run. Priority:
# 1) first argument ($1) if provided
# 2) REGISTRY/CONTAINER_REPO env vars (if both set)
if [ "${1-}" != "" ]; then
  image="$1"
elif [ -n "${REGISTRY-}" ] && [ -n "${CONTAINER_REPO-}" ]; then
  image="${REGISTRY}/${CONTAINER_REPO}"
else
  echo "Usage: $0 <image-ref>  (or set REGISTRY and CONTAINER_REPO env vars)"
  exit 2
fi

# Append :latest if no tag or digest is provided
if [[ "$image" != *":"* ]]; then
  image="${image}:latest"
fi

echo "Using image: $image"

# Run the podman container
container_id=$(podman run -d --rm -p 8080:8080 "$image") || { echo "podman run failed"; exit 1; }

# Wait for the container to start
sleep 5

# Test the container via a curl API call
status_code=$(curl -s -o response_body.json -w "%{http_code}" http://localhost:8080/v2/languages || true)

echo "Status code: $status_code"

if [ "$status_code" -ne 200 ]; then
  echo "Failed to get a 200 status code"
  podman stop "$container_id" >/dev/null 2>&1 || true
  exit 1
fi

echo "Response body:"
cat response_body.json

echo "Language count:"
COUNT=$(jq '. | length' response_body.json)

if [ "$COUNT" -lt 50 ]; then
  echo "Language Count too low to be valid"
  podman stop "$container_id" >/dev/null 2>&1 || true
  exit 1
fi

# Stop the container
podman stop "$container_id"
