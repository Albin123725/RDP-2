#!/bin/bash
# 🔒 Fix SSL Certificate Issues for Chrome/GitHub Codespaces

echo "🔧 Fixing SSL certificate issues..."

# Update CA certificates
update-ca-certificates

# Create Chrome policy to disable certificate warnings
mkdir -p /etc/chromium/policies/managed
cat > /etc/chromium/policies/managed/certificate_policy.json << 'EOF'
{
  "AutoSelectCertificateForUrls": [
    {
      "pattern": "https://github.dev",
      "filter": {
        "ISSUER": {
          "CN": "GitHub Codespaces"
        }
      }
    }
  ],
  "SSLVersionMin": "tls1",
  "OriginBoundCertEnabled": false,
  "CertificateTransparencyEnforcementDisabledForUrls": [
    "https://github.dev",
    "https://*.github.dev"
  ]
}
EOF

# Create Chrome flags configuration
mkdir -p /home/browseruser/.config/chromium
cat > /home/browseruser/.config/chromium/Enabled\ experiments << 'EOF'
ignore-certificate-errors@1
allow-insecure-localhost@1
disable-web-security@1
EOF

# Create Chrome user data directory with certificate exceptions
mkdir -p /tmp/chrome-default
cat > /tmp/chrome-default/Preferences << 'EOF'
{
  "profile": {
    "content_settings": {
      "exceptions": {
        "certificate_errors": {
          "https://github.dev,*": {
            "last_modified": "13337444166968082",
            "setting": 1
          },
          "https://*.github.dev,*": {
            "last_modified": "13337444166968082",
            "setting": 1
          }
        }
      }
    }
  }
}
EOF

# Download GitHub's public certificate (optional)
echo "Downloading GitHub certificates..."
mkdir -p /usr/local/share/ca-certificates/github
wget -q -O /usr/local/share/ca-certificates/github/github-dev.crt https://crt.sh/?d=2489720661 2>/dev/null || true

# Update certificates again
update-ca-certificates

# Set environment variable to ignore certificate errors
export NODE_TLS_REJECT_UNAUTHORIZED=0
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

echo "✅ Certificate fixes applied"
echo "   • Chrome will ignore certificate errors"
echo "   • GitHub Codespaces certificates accepted"
echo "   • No more 'Not Secure' warnings"
