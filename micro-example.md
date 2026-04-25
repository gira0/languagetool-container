Rootless build helper
---------------------

This repo includes a rootless Buildah helper script to build a UBI-micro image with the JDK without relying on a rootful Docker daemon:

```bash
bash scripts/build-ubi-micro-buildah-rootless.sh languagetool:ubi-micro-jdk21
```

The script attempts `buildah bud` (rootless-friendly) first, and falls back to a `buildah from` + `dnf --installroot` population method if needed.

Historical low-level Buildah example (UBI 9 example):

microcontainer=$(buildah from registry.access.redhat.com/ubi9/ubi-micro)
micromount=$(buildah mount $microcontainer)

dnf install \
    --installroot $micromount \
    --releasever 9 \
    --setopt install_weak_deps=false \
    --nodocs -y \
    java-21-openjdk-headless

dnf clean all \
    --installroot $micromount

buildah umount $microcontainer
buildah commit $microcontainer ubi-micro-jdk21

Also see `Dockerfile.ubibuild` for an alternative multi-stage build approach (builder: `ubi`, final: `ubi-micro`).