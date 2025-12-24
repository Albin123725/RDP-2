# 🚀 Ultra-Minimal RDP Browser - Fixed Certificate Issue
FROM alpine:edge

# Install ALL packages
RUN apk add --no-cache --update \
    # Browser with latest Chromium
    chromium \
    chromium-chromedriver \
    # X11 display
    xvfb \
    x11vnc \
    # Minimal window manager
    fluxbox \
    # Web VNC
    novnc \
    websockify \
    # Python with build tools
    python3 \
    py3-pip \
    # Build tools for Python packages
    gcc \
    musl-dev \
    python3-dev \
    linux-headers \
    # System dependencies
    dbus \
    ttf-freefont \
    ttf-dejavu \
    bash \
    wget \
    ca-certificates \
    # SSL certificates
    nss \
    # Clean cache
    && rm -rf /var/cache/apk/* \
    && update-ca-certificates

# Create app directory and virtual environment
WORKDIR /app
RUN python3 -m venv /app/venv

# Install Python packages
RUN /app/venv/bin/pip install --no-cache-dir --upgrade pip && \
    /app/venv/bin/pip install --no-cache-dir \
    flask==2.3.3 \
    gunicorn==21.2.0 \
    psutil==5.9.5

# Create non-root user
RUN adduser -D -u 1000 browseruser \
    && mkdir -p /home/browseruser/.config \
    && chown -R browseruser:browseruser /home/browseruser

# Copy application files
COPY rdp-browser.py /app/
COPY fix-certificates.sh /app/

# Make certificate fix script executable
RUN chmod +x /app/fix-certificates.sh

# Set environment variables for Chrome to ignore certificate errors
ENV DISPLAY=:99
ENV CHROMIUM_FLAGS="--no-sandbox --disable-dev-shm-usage --disable-gpu --ignore-certificate-errors --ignore-urlfetcher-cert-requests --allow-running-insecure-content --disable-web-security --user-data-dir=/tmp/chrome"
ENV HOME=/tmp
ENV PORT=10000
ENV PATH="/app/venv/bin:$PATH"
ENV PYTHONPATH="/app/venv/lib/python3.12/site-packages"
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
ENV NODE_TLS_REJECT_UNAUTHORIZED=0

# Create optimized startup script with certificate fixes
RUN echo '#!/bin/bash' > /app/start.sh && \
    echo 'set -e' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo 'echo "=========================================="' >> /app/start.sh && \
    echo 'echo "🚀 Starting Ultra-Minimal RDP Browser"' >> /app/start.sh && \
    echo 'echo "=========================================="' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Run certificate fix script' >> /app/start.sh && \
    echo 'bash /app/fix-certificates.sh' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Export environment' >> /app/start.sh && \
    echo 'export PATH="/app/venv/bin:$PATH"' >> /app/start.sh && \
    echo 'export DISPLAY=:99' >> /app/start.sh && \
    echo 'export CHROMIUM_FLAGS="--no-sandbox --disable-dev-shm-usage --disable-gpu --ignore-certificate-errors --ignore-urlfetcher-cert-requests --allow-running-insecure-content --disable-web-security --user-data-dir=/tmp/chrome"' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Create Chrome data directory' >> /app/start.sh && \
    echo 'mkdir -p /tmp/chrome' >> /app/start.sh && \
    echo 'chmod 777 /tmp/chrome' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start Xvfb' >> /app/start.sh && \
    echo 'Xvfb :99 -screen 0 1280x1024x24 -ac +extension GLX +render -noreset 2>/dev/null &' >> /app/start.sh && \
    echo 'sleep 3' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start fluxbox' >> /app/start.sh && \
    echo 'fluxbox 2>/dev/null &' >> /app/start.sh && \
    echo 'sleep 2' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# IMPORTANT: First launch Chrome to accept certificates' >> /app/start.sh && \
    echo 'echo "Configuring Chrome to accept certificates..."' >> /app/start.sh && \
    echo 'chromium-browser $CHROMIUM_FLAGS \' >> /app/start.sh && \
    echo '  --test-type \' >> /app/start.sh && \
    echo '  --ignore-certificate-errors-spki-list="PhrPvGIaAMmd29hj8BCZOq096yj7uMpRNHpn5PDxI6I=" \' >> /app/start.sh && \
    echo '  --allow-insecure-localhost \' >> /app/start.sh && \
    echo '  --disable-features=IsolateOrigins,site-per-process \' >> /app/start.sh && \
    echo '  about:blank 2>/dev/null &' >> /app/start.sh && \
    echo 'FIRST_PID=$!' >> /app/start.sh && \
    echo 'sleep 5' >> /app/start.sh && \
    echo 'kill $FIRST_PID 2>/dev/null' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Now start Chrome with the target URL' >> /app/start.sh && \
    echo 'echo "Loading target website..."' >> /app/start.sh && \
    echo 'chromium-browser $CHROMIUM_FLAGS \' >> /app/start.sh && \
    echo '  --test-type \' >> /app/start.sh && \
    echo '  --ignore-certificate-errors-spki-list="PhrPvGIaAMmd29hj8BCZOq096yj7uMpRNHpn5PDxI6I=" \' >> /app/start.sh && \
    echo '  --allow-insecure-localhost \' >> /app/start.sh && \
    echo '  --disable-features=IsolateOrigins,site-per-process \' >> /app/start.sh && \
    echo '  --window-size=1280,1024 \' >> /app/start.sh && \
    echo '  --window-position=0,0 \' >> /app/start.sh && \
    echo '  --app="https://literate-cod-g474wqj4x9f59p.github.dev/?editor=jupyter" 2>/dev/null &' >> /app/start.sh && \
    echo 'MAIN_PID=$!' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start VNC server' >> /app/start.sh && \
    echo 'x11vnc \' >> /app/start.sh && \
    echo '  -display :99 \' >> /app/start.sh && \
    echo '  -forever \' >> /app/start.sh && \
    echo '  -shared \' >> /app/start.sh && \
    echo '  -nopw \' >> /app/start.sh && \
    echo '  -listen 0.0.0.0 \' >> /app/start.sh && \
    echo '  -rfbport 5901 \' >> /app/start.sh && \
    echo '  -noxdamage 2>/dev/null &' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start noVNC web interface' >> /app/start.sh && \
    echo 'websockify --web /usr/share/novnc 6081 localhost:5901 2>/dev/null &' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start Flask control panel' >> /app/start.sh && \
    echo 'cd /app && python3 rdp-browser.py 2>/dev/null &' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo 'echo "✅ RDP Browser Ready!"' >> /app/start.sh && \
    echo 'echo ""' >> /app/start.sh && \
    echo 'echo "🌐 Control Panel: http://localhost:10000"' >> /app/start.sh && \
    echo 'echo "🔗 Web VNC: http://localhost:6081/vnc.html"' >> /app/start.sh && \
    echo 'echo "🎯 Target: https://literate-cod-g474wqj4x9f59p.github.dev/?editor=jupyter"' >> /app/start.sh && \
    echo 'echo "🔒 Certificate errors are suppressed"' >> /app/start.sh && \
    echo 'echo "=========================================="' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Keep container alive' >> /app/start.sh && \
    echo 'wait $MAIN_PID' >> /app/start.sh && \
    chmod +x /app/start.sh

# Set permissions
RUN chown -R browseruser:browseruser /app

# Switch to non-root user
USER browseruser

# Expose ports
EXPOSE 10000 5901 6081

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD wget --quiet --tries=1 --no-check-certificate --spider http://localhost:10000/health || exit 1

# Start the service
CMD ["/bin/bash", "/app/start.sh"]
