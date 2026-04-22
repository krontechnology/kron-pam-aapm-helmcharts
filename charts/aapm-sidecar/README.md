# kron-aapm-sidecar Helm Chart

Deploys the AAPM Sidecar Injector on Kubernetes. It consists of two components:

- **aapm-hook** — a Kubernetes mutating admission webhook (Go) that automatically injects the sidecar into pods
- **aapm-client** — a Spring Boot application (`aapm-client` profile) injected as a sidecar that polls the AAPM Agent and writes secrets to a shared `/keystore` volume

### How It Works

```
Pod creation request
        ↓
aapm-hook (MutatingWebhookConfiguration)
        ↓  injects into pods in labeled namespaces
Application Pod
  ├── Main container         ← reads /keystore/{label}.env
  └── aapm-client (sidecar)  ← polls AAPM Agent every 30s, writes to /keystore
        ↓
AAPM Agent
```

The sidecar runs as profile `aapm-client`. It polls the AAPM Agent on a schedule and writes fetched passwords to files in the shared `/keystore` volume so the main application can read them.

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

### Step 1 — Create and label the target namespace

The webhook only injects into namespaces labeled `aapm-injection: enabled`.

```bash
kubectl create namespace <target_namespace>
kubectl label namespace <target_namespace> aapm-injection=enabled
```

### Step 2 — Create required resources in the target namespace

The injected sidecar reads its configuration from resources that must exist in the **target namespace** (the namespace where your application pods run).

**Create `aapm-client-secret`:**

```bash
cat <<'EOF' > /tmp/application-aapm-client.yml
aapm:
  client:
    poll-interval-ms: 30000
    secrets:
      - userLabel: "account-1"
        secret: "<account-name-1>"
        token: "<token-1>"
        accPath: "/"
      - userLabel: "account-2"
        secret: "<account-name-2>"
        token: "<token-2>"
        accPath: "/"
EOF

kubectl create secret generic aapm-client-secret \
    --namespace <target_namespace> \
    --from-literal=AGENT_SERVICE="kron-aapm-agent.<agent_namespace>.svc.cluster.local" \
    --from-literal=AGENT_PORT="8080" \
    --from-literal=DIRECT_ACCESS_URL="https://<your-pam-url>" \
    --from-file=application-aapm-client.yml=/tmp/application-aapm-client.yml
```

**Create `aapm-configmap`:**

```bash
kubectl create configmap aapm-configmap \
    --namespace <target_namespace> \
    --from-literal=aapm.conf="# AAPM client configuration"
```

### Step 3 — Install the chart

```bash
helm install kron-aapm-sidecar kron-pam/kron-aapm-sidecar \
    --namespace <namespace_name> \
    --create-namespace \
    --set namespace.name=<namespace_name> \
    --set aapmConnection.agentService="kron-aapm-agent.<agent_namespace>.svc.cluster.local" \
    --set aapmConnection.agentPort=8080 \
    --set aapmConnection.directAccessUrl="https://<your-pam-url>" \
    --set aapmConnection.ignoreCertificate=true \
    --set aapmConnection.ignoreInterceptorCertificate=true
```

> `<namespace_name>` is where the injector runs. `<target_namespace>` is where your app pods run. These can be the same or different namespaces.

---

## Verify Injection

Deploy a test pod in the target namespace and check the files:

```bash
kubectl run test-pod --image=nginx --namespace <target_namespace>

# List files written by the sidecar
kubectl exec test-pod -c aapm-client -n <target_namespace> -- ls -la /keystore

# Read a secret file
kubectl exec test-pod -c aapm-client -n <target_namespace> -- cat /keystore/account-1.env
```

---

## Opting Out of Injection

By default, all pods in labeled namespaces are injected. To exclude a specific pod, add the annotation:

```yaml
annotations:
  aapm-sidecar-injector.kron.com/inject: "false"
```

The `kron-aapm-agent` deployment already sets this annotation automatically.

---

## Secret Output Format

For each entry in `aapmClient.secrets`, the sidecar writes two files inside the shared `/keystore` volume:

| File | Content |
|---|---|
| `/keystore/{userLabel}.env` | `secret_name=password_value` |
| `/keystore/config` | `export secret_name=password_value` |

The main application container can source `/keystore/config` or read individual `.env` files to consume the secrets.

---

## Configuration Reference

| Parameter | Description | Default |
|---|---|---|
| `namespace.name` | Namespace where the injector is deployed | required |
| `aapmConnection.agentService` | In-cluster DNS of the AAPM Agent service | `""` |
| `aapmConnection.agentPort` | AAPM Agent gRPC port | `443` |
| `aapmConnection.directAccessUrl` | Direct PAM URL fallback | `""` |
| `aapmConnection.ignoreCertificate` | Skip certificate verification for agent connection | `false` |
| `aapmConnection.ignoreInterceptorCertificate` | Skip certificate verification for interceptor | `false` |
| `aapmConnection.disableSecureChannel` | Disable secure gRPC channel to agent | `false` |
| `aapmConnection.disableInterceptorSecureRequest` | Disable HTTPS for interceptor requests | `false` |
| `aapmClient.pollIntervalMs` | How often (ms) the sidecar fetches secrets | `30000` |
| `aapmClient.secrets` | List of secret accounts to fetch (written to `aapm-client-secret` in injector namespace) | `[]` |
| `aapmClient.secrets[].userLabel` | Label used as the output filename in `/keystore` | required |
| `aapmClient.secrets[].secret` | Account name in the AAPM Agent | required |
| `aapmClient.secrets[].token` | Auth token for the account | required |
| `aapmClient.secrets[].accPath` | Account path in the PAM hierarchy | required |
| `image.repository` | Webhook injector image | `krontechnology/aapm-sidecar-injector` |
| `image.tag` | Webhook injector image tag | `"1.2.1"` |
| `sidecarImage.repository` | Sidecar (aapm-client) image | `krontechnology/aapm-client` |
| `sidecarImage.tag` | Sidecar image tag | `"1.2.1"` |
| `service.port` | Webhook service port | `443` |
| `volumeMounts.path` | Shared volume mount path for secrets | `"/keystore"` |
| `replicaCount` | Number of webhook injector replicas | `1` |

---

## Upgrade

After updating `aapm-client-secret` in the target namespace, restart the injector and recreate pods to pick up changes:

```bash
helm upgrade kron-aapm-sidecar kron-pam/kron-aapm-sidecar \
    --namespace <namespace_name> \
    --set namespace.name=<namespace_name> \
    --set aapmConnection.agentService="kron-aapm-agent.<agent_namespace>.svc.cluster.local" \
    --set aapmConnection.agentPort=8080 \
    --set aapmConnection.directAccessUrl="https://<your-pam-url>" \
    --set aapmConnection.ignoreCertificate=true \
    --set aapmConnection.ignoreInterceptorCertificate=true

kubectl rollout restart deployment/kron-aapm-sidecar -n <namespace_name>
```

## Uninstall

```bash
helm uninstall kron-aapm-sidecar -n <namespace_name>
```

The webhook's `preStop` hook automatically removes the `MutatingWebhookConfiguration` when the pod terminates, so no manual cleanup is needed.
