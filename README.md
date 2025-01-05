# kron-pam-aapm-helmcharts
It contains the source code for the kubernetes `Helm Chart`s that can make requests to the Vault password vault defined in the Kron PAM product developed by the Kron company


# Installation

1. create keystore file (Optional)
```
KEYSTORE_NAME="keystore.p12"
ALIAS_NAME="kron-alias"
KEYSTORE_PASSWORD="topsecret"
KEY_PASSWORD="topsecret"
CERT_DN="CN=kron-pam-aapm-service,OU=IT,O=Kron,L=Turkiye,ST=Istanbul,C=TR"
VALIDITY_DAYS=365

keytool -genkeypair \
  -alias "$ALIAS_NAME" \
  -keyalg RSA \
  -keysize 2048 \
  -dname "$CERT_DN" \
  -validity "$VALIDITY_DAYS" \
  -keypass "$KEY_PASSWORD" \
  -keystore "$KEYSTORE_NAME" \
  -storepass "$KEYSTORE_PASSWORD" \
  -storetype PKCS12
```

2. create namespace
```
kubectl create namespace kron-pam-aapm
```

3. create secret in namespace (Optional)
```
kubectl create secret generic kron-pam-aapm-secret --from-file=keystore.p12=keystore.p12 -n kron-pam-aapm
```

4. install agent 
```
helm install kron-pam-aapm-agent charts/aapm-agent \
  --namespace kron-pam-aapm \
  --create-namespace \
  --set secrets.installToken="d7d...608e" \
  --set secrets.address="localhost"
```
5. install service
  - with ssl:
    ```
    helm install kron-pam-aapm-service charts/aapm-service \
    --namespace kron-pam-aapm \
    --set tls.enabled=true \
    --set tls.password="topsecret" \
    --set tls.alias="kron-alias" 
    ```
  - no ssl:
    ```
    helm install kron-pam-aapm-service charts/aapm-service \
    --namespace kron-pam-aapm
    ```
    ### Note: 
    When installing aapm-agent with providing `secrets.address`, a secret will be created and aapm-service will use it. 
    If you don't, provide pam url: `--set pam.url="localhost"`
6. testing service
```
helm test kron-pam-aapm-service
```

# Requesting To Service

Make `POST` request to endpoint: `<service>/vault` with required parameters

```
curl -k -X POST https://kron-pam-aapm-service:8443/vault \
-H "Content-Type: application/json" \
-d '{
  "token": "<token>",
  "accountName": "<vault_name>",
  "accountPath": "<account_path>"
}'
```


