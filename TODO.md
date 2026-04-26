# TODO — UBI-based improvement plan for LanguageTool container

Goal: produce a lean, secure, production-ready container using RHEL UBI (prefer ubi-micro).

1. Use UBI micro for runtime
   - Done: the final stage now uses a pinned UBI micro base.

2. Build artifact in CI (recommended)
   - Build LanguageTool in GitHub Actions (JDK 21 + mvn -DskipTests), upload artifact, and copy into the image in a separate image-job.

3. Alternative: fetch official release
   - Option: download the LanguageTool release archive from GitHub Releases during build and extract into /opt/languagetool.

4. Harden startup.sh
   - Done: startup now uses `set -eu`, honors `PORT`, and supports `JAVA_OPTS`.

5. Provide OCI-compliant health probe approach
   - Do NOT add the Docker `HEALTHCHECK` instruction (Docker-specific; not part of the OCI image standard).
   - Provide a small executable probe at `/usr/local/bin/lt-healthcheck` that returns exit code 0 when healthy, non-zero otherwise. Keep it minimal (curl or java call).
   - Document the recommended probe command in `README.md` so consumers can configure runtime-specific probes:
     - Docker: `HEALTHCHECK --interval=30s CMD-SHELL /usr/local/bin/lt-healthcheck`
     - Kubernetes: `livenessProbe.exec.command: ["/usr/local/bin/lt-healthcheck"]`
   - Keep `healthcheck.sh` for CI image validation; make it robust and runtime-agnostic.

6. PID1 / signal forwarding
   - Install and use tini (ENTRYPOINT ["/sbin/tini","--"]) or require --init when running containers.

7. OCI labels & metadata
   - Add standard OCI labels (org.opencontainers.image.*) and image version/maintainer metadata.

8. CI improvements
   - Fix Trivy image-ref to scan the pushed tag; add hadolint linting; add integration job that runs the image and verifies /v2/languages; consider buildx for multi-arch.

9. Documentation
   - Expand README.md with quickstart, env vars (PORT, JAVA_OPTS, LT_DATA_DIR), docker/podman examples, volume mounts, and recommended resource limits.

10. Healthcheck script polish
   - Keep `healthcheck.sh` for CI validation; the runtime container now relies on an external probe instead of debug-heavy startup checks.

11. Licensing & contributing
   - Add CONTRIBUTING.md and confirm license compatibility; add LICENSE if the repository needs one.

12. Optional optimizations
   - Consider jlink/distroless to shrink the JRE, or remove unused files from /opt/languagetool.

Principals:
- Prioritize building in CI + UBI micro runtime.
- Adhere to the OCI Spec
    - spec_target: "v1.1.1"
    - manifest_required_fields: ["mediaType", "layers", "digest"]
    - config_handling: "config MAY be absent for non-runtime artifacts — code must tolerate missing config"
    - index_usage: "use manifest index for multi-platform/manifest lists"
    - platform_descriptor: ["os", "architecture", "variant"]
    - media_types: "recognize and preserve artifact mediaTypes (containers, helm, wasm, sbom, attestations)"
    - annotations: "use standard annotations, avoid reserved keys, preserve consumer-visible metadata"
    - sbom: "include or reference SBOMs and expose/query them via registry endpoints when available"
    - attestations: "support retrieval and verification of signed attestations (runtime/CI provenance)"
    - signing: "verify signatures; support multi-signer workflows and provenance metadata"
    - registry_behavior: "publish by tag and digest, serve content-addressable retrieval"
    - optional_registry_endpoints: ["sbom-query", "attestation-store/query"]
    - validation_checks: ["digest matches content", "size present and correct", "mediaType valid"]
    - canonicalization: "use JSON canonicalization rules for digest calculations"
    - operational_guidance: "plan phased upgrades and fallback handling for older toolchains"
