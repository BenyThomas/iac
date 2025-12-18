# Firewall Rules Matrix (On-Prem RKE2 + Argo CD + Cilium + Harbor)

Implement these controls in NSX-T DFW / Gateway firewall or perimeter ACLs.

## Zones
- MGMT: admin access, Ansible
- NODES: all Kubernetes nodes
- STORAGE: storage network (NFS/iSCSI/vSAN)
- DMZ/INGRESS: inbound traffic to ingress VIPs
- HARBOR-VMs: Harbor registry VMs

## Core DNS/NTP
- NODES -> DNS: TCP/UDP 53
- NODES -> NTP: UDP 123

## Kubernetes / RKE2
- MGMT -> API VIP: TCP 6443
- Workers -> API VIP: TCP 6443
- Workers -> RKE2 servers: TCP 9345
- Control-plane <-> Control-plane: TCP 2379-2380 (etcd)
- Control-plane -> Nodes: TCP 10250 (kubelet API; restrict sources)
- Control-plane health endpoints (internal): TCP 10257, 10259

## Cilium (confirm datapath)
If using encapsulation:
- Node <-> Node: UDP 8472 (VXLAN) OR UDP 6081 (Geneve)
If using direct routing:
- Allow required routed pod/service CIDRs and node-to-node traffic per design.

## Ingress
- Client -> Ingress VIP: TCP 80/443

## Harbor Registry (on VMs)
- CI/Jenkins agents -> registry.<domain>: TCP 443 (push)
- Nodes -> registry.<domain>: TCP 443 (pull)
- MGMT -> Harbor UI: TCP 443 (restrict)

## Monitoring/Logging (examples)
- MGMT -> Grafana: TCP 443/3000 (prefer 443 behind reverse proxy)
- Prometheus -> scrape targets: TCP 9100/10250/etc (lock down)
- Log shippers -> log store: per chosen stack (Loki/ELK ports)

Principle: least privilege; no broad any-any between zones.
