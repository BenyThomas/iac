# Pipelines

Jenkins pipeline template that runs on Kubernetes dynamic agents. The template delivers a full CI/CD supply chain: build, test, package, image build/push, GitOps update, and layered security checks (SAST, SCA, secrets, container, IaC, and DAST).

## Template highlights
- Uses the Jenkins Kubernetes plugin with a pod template that supplies build tools, Kaniko, Trivy, Semgrep, Gitleaks, Cosign, and OWASP ZAP. Resource requests/limits and `workload=ci` node selectors keep agents elastic but constrained.
- Pulls and publishes images via Harbor proxy caches (`dockerhub-proxy`, `ghcr-proxy`, `quay-proxy`) using environment-aware robot credentials.
- Enforces severity thresholds per environment for container and IaC scans, blocks secrets in source, and fails on SAST/SCA findings.
- Signs and attests images with Cosign and performs an admission dry run against the in-cluster public key.
- Optional DAST stage runs OWASP ZAP against a provided URL and archives reports for export.

## Usage
1. Copy `Jenkinsfile.template` into your repo as `Jenkinsfile`.
2. Define Jenkins credentials:
   - `harbor-robot-<env>`: username/password for Harbor robot accounts.
   - `cosign-key`: secret text containing the Cosign private key (or enable keyless and adjust the `Sign & Attest` stage).
   - `SECURITY_REPORT_WEBHOOK` (optional): secret text or string parameter for exporting ZAP results.
3. Set pipeline parameters or environment variables:
   - `DEPLOY_ENV` (`dev|uat|prod`) — drives Harbor project selection and severity gates.
   - `IMAGE_NAME` — image name override (defaults to repository name).
   - `DAST_TARGET_URL` — target endpoint for the ZAP baseline scan (leave empty to skip DAST).
4. Ensure the Kubernetes cluster has nodes labeled `workload=ci` (for agents) and `workload=platform` (for the controller), plus network access from agents to Harbor and the DAST target.

## Security notes
- Secret scanning (Gitleaks) fails the pipeline on leaked credentials before any artifact leaves the cluster.
- Semgrep SAST and Trivy SCA/IaC scans emit JSON reports into `reports/` and fail on findings that cross the configured severities.
- Container images are scanned with Trivy using per-environment gates, then signed and attested with Cosign. Verify policies with `cosign verify --key k8s://configmap/cosign-public-key/key`.
- ZAP baseline results are archived and optionally POSTed to an external reporting system via `SECURITY_REPORT_WEBHOOK`.
