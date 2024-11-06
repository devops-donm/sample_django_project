#!/bin/bash

# Variables (edit these as needed)
DOMAIN="domain.com"                        # Primary domain
ALT_DOMAIN="www.domain.com"                # Alternative domain
CERT_DIR="/opt/docker_volume/nginx/certs"  # Directory to store the certificate
KEY_FILE="${CERT_DIR}/${DOMAIN}.key"
CERT_FILE="${CERT_DIR}/${DOMAIN}.crt"
DAYS_VALID=365                             # Certificate validity in days

# Ensure the certificate directory exists
mkdir -p "${CERT_DIR}"
chmod 755 "${CERT_DIR}"

# Generate OpenSSL configuration with SANs
CONFIG_FILE="${CERT_DIR}/openssl.cnf"
cat > "${CONFIG_FILE}" <<EOL
[ req ]
default_bits       = 2048
distinguished_name = req_distinguished_name
req_extensions     = req_ext
x509_extensions    = v3_ca
prompt             = no

[ req_distinguished_name ]
C  = US
ST = State
L  = City
O  = Organization
OU = Org Unit
CN = ${DOMAIN}

[ req_ext ]
subjectAltName = @alt_names

[ v3_ca ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = ${DOMAIN}
DNS.2 = ${ALT_DOMAIN}
EOL

# Generate private key without encryption
if [[ ! -f "${KEY_FILE}" ]]; then
  echo "Generating private key..."
  openssl genpkey -algorithm RSA -out "${KEY_FILE}"
else
  echo "Private key already exists at ${KEY_FILE}"
fi

# Generate self-signed certificate with SANs
if [[ ! -f "${CERT_FILE}" ]]; then
  echo "Generating self-signed certificate with SANs..."
  openssl req -new -x509 -key "${KEY_FILE}" -out "${CERT_FILE}" -days "${DAYS_VALID}" -config "${CONFIG_FILE}"
else
  echo "Certificate already exists at ${CERT_FILE}"
fi

# Cleanup
rm -f "${CONFIG_FILE}"

# Display result
echo "Certificate and key generated in ${CERT_DIR}"
