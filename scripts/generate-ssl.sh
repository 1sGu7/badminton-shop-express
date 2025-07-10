#!/bin/bash

# Generate self-signed SSL certificate for development
# This script creates SSL certificates for nginx

SSL_DIR="nginx/ssl"
CERT_FILE="$SSL_DIR/cert.pem"
KEY_FILE="$SSL_DIR/key.pem"

# Create SSL directory if it doesn't exist
mkdir -p "$SSL_DIR"

# Generate self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$KEY_FILE" \
    -out "$CERT_FILE" \
    -subj "/C=VN/ST=Hanoi/L=Hanoi/O=BadmintonShop/OU=IT/CN=localhost"

# Set proper permissions
chmod 600 "$KEY_FILE"
chmod 644 "$CERT_FILE"

echo "SSL certificates generated successfully!"
echo "Certificate: $CERT_FILE"
echo "Private Key: $KEY_FILE"
echo ""
echo "Note: These are self-signed certificates for development only."
echo "For production, use certificates from a trusted CA." 