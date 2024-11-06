#!/bin/bash

# Variables (edit these as needed)
DOMAIN="domain.com"              # Primary domain
ALT_DOMAIN="www.domain.com"      # Alternative domain
CERT_DIR="/opt/docker_volume/nginx/certs"  # Directory to store the certificate
KEY_FILE="${CERT_DIR}/${DOMAIN}.key"
CERT_FILE="${CERT_DIR}/${DOMAIN}.crt"
DAYS_VALID=365                   # Certificate validity in days
DAYS_THRESHOLD=30                # Days before expiration to regenerate the certificate

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

# Check if certificate is close to expiring
REGENERATE_CERT=false
if [[ -f "${CERT_FILE}" ]]; then
  # Extract the expiration date and calculate days until expiration
  EXPIRATION_DATE=$(openssl x509 -enddate -noout -in "${CERT_FILE}" | cut -d= -f2)
  EXPIRATION_EPOCH=$(date -d "${EXPIRATION_DATE}" +%s)
  CURRENT_EPOCH=$(date +%s)
  DAYS_LEFT=$(( (EXPIRATION_EPOCH - CURRENT_EPOCH) / 86400 ))

  echo "Certificate expires in ${DAYS_LEFT} days."

  # Check if expiration is within the threshold
  if (( DAYS_LEFT <= DAYS_THRESHOLD )); then
    echo "Certificate is within ${DAYS_THRESHOLD} days of expiring. Regenerating..."
    REGENERATE_CERT=true
  else
    echo "Certificate is valid for more than ${DAYS_THRESHOLD} days. No need to regenerate."
  fi
else
  echo "No existing certificate found. Generating a new certificate..."
  REGENERATE_CERT=true
fi

# Generate private key without encryption if it doesn't exist
if [[ ! -f "${KEY_FILE}" ]]; then
  echo "Generating private key..."
  openssl genpkey -algorithm RSA -out "${KEY_FILE}"
else
  echo "Private key already exists at ${KEY_FILE}"
fi

# Generate self-signed certificate with SANs if needed
if [[ "${REGENERATE_CERT}" == true ]]; then
  echo "Generating self-signed certificate with SANs..."
  openssl req -new -x509 -key "${KEY_FILE}" -out "${CERT_FILE}" -days "${DAYS_VALID}" -config "${CONFIG_FILE}"
else
  echo "Certificate regeneration not required."
fi

# Cleanup
rm -f "${CONFIG_FILE}"

# Display result
echo "Certificate and key are in ${CERT_DIR}"
