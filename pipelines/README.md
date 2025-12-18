# Pipelines

Jenkins pipeline template that builds, scans, signs, and publishes container images into Harbor with supply chain controls.

## Template highlights
- Pull base images via Harbor proxy cache projects (`dockerhub-proxy`, `ghcr-proxy`, `quay-proxy`).
- Use project-specific robot accounts stored as Jenkins credentials (`harbor-robot-dev|uat|prod`).
- Apply environment-aware Trivy severity gates and emit Cosign signatures + vulnerability attestations.
- Keep secrets out of logs via `withCredentials` and masked environment variables.

## Usage
1. Copy `Jenkinsfile.template` into your repo as `Jenkinsfile`.
2. Create Jenkins credentials:
   - `harbor-robot-<env>`: username/password for Harbor robot accounts.
   - `cosign-key`: secret text containing the Cosign private key (or set up keyless and remove the key reference).
3. Set pipeline parameters or environment variables:
   - `DEPLOY_ENV` (`dev|uat|prod`) — drives Harbor project selection and severity gates.
   - `IMAGE_NAME` — application image name (defaults to repository name).
4. Ensure the Jenkins agent has Docker/Podman, Trivy, Cosign, and access to Harbor (ingress VIP or internal DNS).

## Security notes
- Robot tokens are only loaded into the `Publish` stage and not echoed to logs.
- Cosign public key must be distributed to the cluster (`platform-services/cosign-public-key`) for admission verification.
- Vulnerability attestation thresholds should mirror the Kyverno policy in `policies/supply-chain/vuln-attestation-thresholds.yaml`.
