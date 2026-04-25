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

# Wait/retry for the container to become healthy. Increase the timeout so Java
# server has time to start in CI. Poll every INTERVAL seconds up to MAX_WAIT.
INTERVAL=${INTERVAL:-5}
MAX_WAIT=${MAX_WAIT:-90}
elapsed=0
status_code=000

echo "Waiting up to ${MAX_WAIT}s for HTTP 200 from container..."
while [ $elapsed -lt $MAX_WAIT ]; do
  status_code=$(curl -s -o response_body.json -w "%{http_code}" http://localhost:8080/v2/languages || true)
  if [ "$status_code" -eq 200 ]; then
    break
  fi
  sleep $INTERVAL
  elapsed=$((elapsed + INTERVAL))
done

echo "Status code: $status_code (after ${elapsed}s)"

if [ "$status_code" -ne 200 ]; then
  echo "Failed to get a 200 status code within ${MAX_WAIT}s"
  echo "=== Container logs (tail) ==="
  podman logs --tail 200 "$container_id" || true
  echo "=== End container logs ==="
  echo "Podman ps -a (relevant lines):"
  podman ps -a --filter id="$container_id" || true
  podman inspect "$container_id" || true
  podman stop "$container_id" >/dev/null 2>&1 || true
  exit 1
fi

echo "Response body:"
cat response_body.json

echo "Language count:"
COUNT=$(jq '. | length' response_body.json)

if [ "$COUNT" -lt 50 ]; then
  echo "Language Count too low to be valid"
  echo "=== Container logs (tail) ==="
  podman logs --tail 200 "$container_id" || true
  echo "=== End container logs ==="
  podman stop "$container_id" >/dev/null 2>&1 || true
  exit 1
fi

# Stop the container
podman stop "$container_id"
