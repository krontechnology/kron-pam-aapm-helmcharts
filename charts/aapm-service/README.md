# aapm-service Helm Chart

Deploys the Kron AAPM Service on Kubernetes. The service acts as a vault proxy between applications and the AAPM Agent, exposing a REST API for password retrieval.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.x
- `kron-aapm-agent` deployed and reachable within the cluster
- Access to the `kron-pam` Helm repository (or a local clone of this chart)

## Add the Helm Repository

```bash
helm repo add kron-pam <repo-url>
helm repo update
```

## Installation

### Basic Installation

Standard deployment where the service connects directly to the AAPM Agent.

```bash
helm install aapm-service kron-pam/aapm-service \
    --namespace <namespace_name> \
    --create-namespace \
    --set agent.service="kron-aapm-agent.<namespace_name>.svc.cluster.local" \
    --set agent.port="8080" \
    --set pam.url="<your-pam-url>" \
    --set agent.ignoreCertificate=true \
    --set interceptor.ignoreCertificate=true
```

---

### Option 2 — With TLS Enabled

Enables HTTPS on the service using a PKCS12 keystore.

**Step 1 — Create the TLS secret:**

```bash
kubectl create secret generic grpc-tls-secret \
    --from-file=keystore.p12=/path/to/keystore.p12 \
    --namespace <namespace_name>
```

**Step 2 — Install the chart:**

```bash
helm install aapm-service kron-pam/aapm-service \
    --namespace <namespace_name> \
    --create-namespace \
    --set agent.service="kron-aapm-agent.<namespace_name>.svc.cluster.local" \
    --set agent.port="8080" \
    --set pam.url="<your-pam-url>" \
    --set tls.enabled=true \
    --set tls.password="<your-keystore-password>" \
    --set tls.keyAlias="<your-key-alias>" \
    --set tls.secretName="grpc-tls-secret"
```

---

## Test the Installation

Forward the service port and verify it is running:

```bash
kubectl port-forward svc/aapm-service 8443:8443 -n <namespace_name>
```

Health check:
```bash
curl -k http://localhost:8443/vault
# Expected: Debug mode enabled!
```

Fetch a password:
```bash
curl -k -X POST http://localhost:8443/vault \
    -H "Content-Type: application/json" \
    -d '{
        "accountName": "<account-name>",
        "accountPath": "/",
        "token": "<token>"
    }'
```

---

## Configuration Reference

| Parameter | Description | Default |
|---|---|---|
| `agent.service` | In-cluster DNS name of the AAPM Agent service | `"<your_agent_url>"` |
| `agent.port` | AAPM Agent gRPC port | `"<your_agent_port>"` |
| `agent.disableSecureChannel` | Disable secure gRPC channel to agent | `false` |
| `agent.ignoreCertificate` | Skip certificate verification for agent | `false` |
| `interceptor.disableSecureRequest` | Disable HTTPS for interceptor requests | `false` |
| `interceptor.ignoreCertificate` | Skip certificate verification for interceptor | `false` |
| `pam.url` | Direct PAM server URL | `"<your_pam_url>"` |
| `tls.enabled` | Enable HTTPS on the service | `false` |
| `tls.keystorePath` | Path to PKCS12 keystore inside the container | `"/etc/tls/keystore.p12"` |
| `tls.password` | Keystore password | `""` |
| `tls.keyAlias` | Key alias in the keystore | `""` |
| `tls.secretName` | Kubernetes secret containing the keystore | `"grpc-tls-secret"` |
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.port` | Service port | `8443` |
| `replicaCount` | Number of replicas | `1` |
| `image.tag` | Image tag override | `"1.1.2"` |

## Upgrade

```bash
helm upgrade aapm-service kron-pam/aapm-service \
    --namespace <namespace_name> \
    --set agent.service="kron-aapm-agent.<namespace_name>.svc.cluster.local" \
    --set agent.port="8080" \
    --set pam.url="<your-pam-url>"
```

## Uninstall

```bash
helm uninstall aapm-service -n <namespace_name>
```
