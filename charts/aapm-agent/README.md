# kron-aapm-agent Helm Chart

Deploys the Kron AAPM Agent on Kubernetes.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.x
- Access to the `kron-pam` Helm repository (or a local clone of this chart)

## Add the Helm Repository

```bash
helm repo add kron-pam <repo-url>
helm repo update
```

## Installation

### Option 1 — Classpath Certificates (default)

The image ships with built-in certificates. No secret setup required.

```bash
helm install kron-aapm-agent kron-pam/kron-aapm-agent \
    --namespace <namespace_name> \
    --create-namespace \
    --set secrets.installToken="<your-install-token>" \
    --set secrets.address="<your-pam-address>"
```

---

### Option 2 — External PEM Certificate + Key

Use your own PEM-format certificate and private key files.

**Step 1 — Create the certificate secret:**

```bash
kubectl create secret generic aapm-agent-certs \
    --from-file=server.crt=/path/to/server.crt \
    --from-file=server.pem=/path/to/server.pem \
    --namespace <namespace_name>
```

> The `--from-file` key names (`server.crt`, `server.pem`) become the filenames inside the container.

**Step 2 — Install the chart:**

```bash
helm install kron-aapm-agent kron-pam/kron-aapm-agent \
    --namespace <namespace_name> \
    --create-namespace \
    --set secrets.installToken="<your-install-token>" \
    --set secrets.address="<your-pam-address>" \
    --set config.app.grpc.security.dist.certChain="file:/etc/kron-agent/certs/server.crt" \
    --set config.app.grpc.security.dist.privateKey="file:/etc/kron-agent/certs/server.pem" \
    --set "extraVolumes[0].name=aapm-agent-certs" \
    --set "extraVolumes[0].secret.secretName=aapm-agent-certs" \
    --set "extraVolumeMounts[0].name=aapm-agent-certs" \
    --set "extraVolumeMounts[0].mountPath=/etc/kron-agent/certs" \
    --set "extraVolumeMounts[0].readOnly=true"
```

---

### Option 3 — External JKS Keystore

Use a JKS keystore file instead of separate PEM files.

**Step 1 — Create the certificate secret:**

```bash
kubectl create secret generic aapm-agent-certs \
    --from-file=server.jks=/path/to/server.jks \
    --namespace <namespace_name>
```

**Step 2 — Install the chart:**

```bash
helm install kron-aapm-agent kron-pam/kron-aapm-agent \
    --namespace <namespace_name> \
    --create-namespace \
    --set secrets.installToken="<your-install-token>" \
    --set secrets.address="<your-pam-address>" \
    --set secrets.keystorePassword="<your-jks-password>" \
    --set config.app.grpc.security.dist.certChain="file:/etc/kron-agent/certs/server.jks" \
    --set config.app.grpc.security.dist.privateKey="file:/etc/kron-agent/certs/server.jks" \
    --set "extraVolumes[0].name=aapm-agent-certs" \
    --set "extraVolumes[0].secret.secretName=aapm-agent-certs" \
    --set "extraVolumeMounts[0].name=aapm-agent-certs" \
    --set "extraVolumeMounts[0].mountPath=/etc/kron-agent/certs" \
    --set "extraVolumeMounts[0].readOnly=true"
```

---

## Convert JKS to PEM (if needed)

If you only have a JKS file and need PEM format:

```bash
# Step 1: JKS → PKCS12
keytool -importkeystore \
    -srckeystore server.jks \
    -destkeystore server.p12 \
    -deststoretype PKCS12

# Step 2: Extract certificate
openssl pkcs12 -in server.p12 -nokeys -out server.crt

# Step 3: Extract private key
openssl pkcs12 -in server.p12 -nocerts -nodes -out server.pem
```

---

## Configuration Reference

| Parameter | Description | Default |
|---|---|---|
| `secrets.installToken` | Agent install token from PAM | `""` |
| `secrets.address` | PAM server address | `""` |
| `secrets.failoverAddress` | PAM failover address | `""` |
| `secrets.keystorePassword` | JKS keystore password | `""` |
| `config.machineId` | Unique machine identifier for the agent | `"agent-docker"` |
| `config.singleconnect.sslIgnored` | Disable SSL verification for PAM connection | `false` |
| `config.singleconnect.hostnameIgnored` | Disable hostname verification | `false` |
| `config.singleconnect.protocol` | Connection protocol | `"https"` |
| `config.singleconnect.agentName` | Agent display name | `"default-agent"` |
| `config.app.grpc.security.enabled` | Enable gRPC TLS | `true` |
| `config.app.grpc.security.dist.certChain` | Path to certificate chain (`classpath:` or `file:`) | `"classpath:cert/server.crt"` |
| `config.app.grpc.security.dist.privateKey` | Path to private key (`classpath:` or `file:`) | `"classpath:cert/server.pem"` |
| `config.grpc.port` | gRPC server port | `8080` |
| `extraVolumes` | Additional volumes to attach to the pod | `[]` |
| `extraVolumeMounts` | Additional volume mounts for the container | `[]` |
| `replicaCount` | Number of replicas | `1` |
| `image.tag` | Image tag override | `"1.8.3"` |
| `service.type` | Kubernetes service type | `NodePort` |
| `service.port` | Service port | `8080` |

## Upgrade

```bash
helm upgrade kron-aapm-agent kron-pam/kron-aapm-agent \
    --namespace <namespace_name> \
    --set secrets.installToken="<your-install-token>" \
    --set secrets.address="<your-pam-address>"
```

## Uninstall

```bash
helm uninstall kron-aapm-agent -n <namespace_name>
```

To also remove the namespace and certificate secret:

```bash
kubectl delete secret aapm-agent-certs -n <namespace_name>
kubectl delete namespace <namespace_name>
```
