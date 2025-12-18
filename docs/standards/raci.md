# RACI — Platform / Security / Application Teams

Legend: R=Responsible, A=Accountable, C=Consulted, I=Informed

| Activity | Platform | Security | App Teams |
|---|---:|---:|---:|
| Target architecture & standards | R/A | C | I |
| vSphere provisioning (Terraform) | R/A | C | I |
| OS baseline & hardening | R | A/C | I |
| RKE2 bootstrap & upgrades | R/A | C | I |
| Cilium deployment & policies | R | A/C | C |
| Harbor operations | R | A/C | I |
| Argo CD GitOps model | R/A | C | C |
| Admission policies (registry/signatures/PSS) | C | R/A | C |
| CI pipelines (Jenkins templates) | R | C | C |
| Observability | R/A | C | I |
| Backups/DR drills | R | A/C | I |
