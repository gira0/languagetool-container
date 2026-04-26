# languagetool-container
Simple container that runs languagetool

Actions:
- [![MAIN - Build Image using Containerfile](https://github.com/gira0/languagetool-container/actions/workflows/build-container-standalone-main.yaml/badge.svg?branch=main)](https://github.com/gira0/languagetool-container/actions/workflows/build-container-standalone-main.yaml)

- [![DEV - Build Image using Containerfile](https://github.com/gira0/languagetool-container/actions/workflows/build-container-standalone-dev.yaml/badge.svg?branch=dev)](https://github.com/gira0/languagetool-container/actions/workflows/build-container-standalone-dev.yaml)

- [![NIGHTLY - Build Image using Containerfile](https://github.com/gira0/languagetool-container/actions/workflows/build-container-standalone-nightly.yaml/badge.svg?branch=main)](https://github.com/gira0/languagetool-container/actions/workflows/build-container-standalone-nightly.yaml)

TODO Docu for options 😁

## Rootless build (local)

This repository provides a rootless Buildah helper that builds a minimal `ubi-micro` image containing the built LanguageTool artifacts.

The current `ubi-micro` image copies the JDK config tree needed by OpenJDK 21, so the final runtime no longer depends on debug-time probes or missing `find` tooling.

Requirements:
- `buildah` or `podman` installed (rootless mode)
- `subuid`/`subgid` configured for your user

Quick local build (preferred, rootless):

```bash
# Use the helper (detects LT version from `Containerfile`):
bash scripts/build-ubi-micro-buildah-rootless.sh languagetool:ubi-micro-jdk21

# Or run directly with buildah (example):
# buildah bud -f Dockerfile.ubibuild --build-arg LT_VER=6.4 -t languagetool:ubi-micro-jdk21 .

# Run and verify:
podman run --rm -it languagetool:ubi-micro-jdk21 java -version
podman run --rm -p 8080:8080 languagetool:ubi-micro-jdk21 /opt/languagetool/startup.sh
```

## CI / Production push

A workflow was added: `.github/workflows/build-ubi-micro.yml` which builds `Dockerfile.ubibuild` using Buildah and pushes to GitHub Container Registry. To enable pushing to a registry, configure the appropriate secrets (`GITHUB_TOKEN` is used for GHCR by default). You may also prefer to use your existing `build-container-standalone-main.yaml` workflow which uses Buildah and already pushes the project image.

Before pushing to production ensure you:
- Include application configuration and secrets via your deployment system (do not bake secrets into the image).
- Run the Trivy scan results and address any critical/high findings.
- Test the image in staging.


