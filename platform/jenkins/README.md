# Jenkins

Jenkins is deployed to Kubernetes with dynamic agents provided by the Kubernetes plugin. The Helm values in this folder configure the controller with a JCasC snippet that provisions ephemeral pods with resource limits, node selectors, and the tooling required by the shared pipeline template.

## Deployment
- Argo CD syncs the Application defined in `platform/argocd/platform-apps/applications/jenkins.yaml`.
- The Kustomize overlay in `platform/jenkins/manifests` renders the upstream Jenkins Helm chart with the values in `../values.yaml`.
- Namespaces are auto-created via the Application `CreateNamespace` sync option.

### Dynamic Kubernetes agents
- The `controller.JCasC` block defines a `ci-default` pod template with containers for build tooling, Kaniko image builds, Trivy, Semgrep, Gitleaks, OWASP ZAP, and Cosign.
- Agents land on nodes labeled `workload=ci` and tolerate a matching taint to protect shared clusters from overload.
- Each container has explicit CPU/memory requests and limits; adjust the `resources` section per container if your workloads need more headroom.
- The Jenkins controller itself is pinned to nodes labeled `workload=platform` so that controllers and agents do not compete for the same capacity.

### Credentials
- Registry robot accounts are referenced as Jenkins credentials `harbor-robot-dev`, `harbor-robot-uat`, and `harbor-robot-prod`.
- Cosign uses a secret text credential `cosign-key` unless keyless signing is enabled; update the pipeline template accordingly.

### Operations
- To change the agent pod spec (e.g., add a new scanner), update `controller.JCasC.configScripts.kubernetes-agents` in `values.yaml` and let Argo CD resync.
- Set `controller.installPlugins` to pin plugin versions that are validated with your controller image. The Kubernetes plugin is included so the controller can launch agents without static worker VMs.
- Override `nodeSelector`/`tolerations` for both controller and agents to align with your cluster topology.
