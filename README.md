# languagetool-container

Container image for the LanguageTool HTTP server.

Actions:
- [![MAIN - Build Image using Containerfile](https://github.com/gira0/languagetool-container/actions/workflows/build-container-standalone-main.yaml/badge.svg?branch=main)](https://github.com/gira0/languagetool-container/actions/workflows/build-container-standalone-main.yaml)

- [![DEV - Build Image using Containerfile](https://github.com/gira0/languagetool-container/actions/workflows/build-container-standalone-dev.yaml/badge.svg?branch=dev)](https://github.com/gira0/languagetool-container/actions/workflows/build-container-standalone-dev.yaml)

- [![NIGHTLY - Build Image using Containerfile](https://github.com/gira0/languagetool-container/actions/workflows/build-container-standalone-nightly.yaml/badge.svg?branch=main)](https://github.com/gira0/languagetool-container/actions/workflows/build-container-standalone-nightly.yaml)

## Usage

The server listens on port `8080`:

```sh
podman run --rm -p 8080:8080 \
	docker.io/giratot/languagetool:nightly
```

The API is available at `http://localhost:8080/v2/languages`.

By default, the server runs without n-gram data. To enable a language model,
mount the data directory at `/languagetool`:

```sh
podman run --rm -p 8080:8080 \
	-v /path/to/ngrams:/languagetool:ro \
	docker.io/giratot/languagetool:nightly
```

Docker can be used in place of Podman in these commands.

## n-gram data

The weekly `Publish LanguageTool n-gram data` workflow downloads all ZIP
archives listed at [the LanguageTool n-gram download page](https://languagetool.org/download/ngram-data/), validates and extracts them, and publishes an OCI artifact to:

```text
ghcr.io/gira0/languagetool-container/languagetool-ngrams:latest
```

The workflow also supports manual runs. It compares upstream `HEAD` metadata
(`ETag`, modification time, and size) with the previously published manifest
and skips the large downloads when the data has not changed. Downloaded
archives are still checksummed before publication. Content-addressed tags use
the form `sha256-<tarball-content-hash>` and identify the bundled extracted
data, not an individual ZIP archive.

An OCI artifact is not mounted directly by Kubernetes. Pull and extract it in
an init container into a shared volume, then mount that volume at
`/languagetool` in the LanguageTool container. For example, with ORAS:

```sh
oras pull ghcr.io/gira0/languagetool-container/languagetool-ngrams:latest
tar -xzf ngram-data.tar.gz -C /path/to/ngrams
```

The GHCR package must be readable by the Kubernetes workload. For private
packages, provide an appropriate GHCR pull secret to the ORAS init container.

## Building

Build a specific LanguageTool release locally with:

```sh
podman build --build-arg LT_VER=6.4 -t languagetool:local -f Containerfile .
```

`LT_VER` must match an existing `v<version>` tag in the upstream
LanguageTool repository.

## Healthcheck

`healthcheck.sh` runs an image, checks `/v2/languages`, and verifies that at
least 50 languages are returned. It requires Podman, curl, and jq:

```sh
bash healthcheck.sh languagetool:local
```
