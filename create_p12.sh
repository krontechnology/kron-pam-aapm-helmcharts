#!/bin/bash

# Parametreler
KEYSTORE_NAME="keystore.p12"
ALIAS_NAME="kron-alias"
KEYSTORE_PASSWORD="topsecret"
KEY_PASSWORD="topsecret"
CERT_DN="CN=kron-pam-aapm-service,OU=IT,O=Kron,L=Turkiye,ST=Istanbul,C=TR"
VALIDITY_DAYS=365

# 1. Self-signed sertifika oluşturma
echo "Creating a self-signed certificate..."
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

if [ $? -eq 0 ]; then
  echo "Keystore '$KEYSTORE_NAME' created successfully."
  echo "Keystore password: $KEYSTORE_PASSWORD"
  echo "Key alias: $ALIAS_NAME"
else
  echo "Failed to create keystore."
  exit 1
fi
