# 🚀 Ultra-Minimal RDP Browser - Render Compatible
# Uses only port 10000 (Render allows this)
FROM alpine:edge

# Install ALL packages
RUN apk add --no-cache --update \
    # Browser
    chromium \
    chromium-chromedriver \
    # X11 display
    xvfb \
    x11vnc \
    # Minimal window manager
    fluxbox \
    # Web VNC (noVNC)
    novnc \
    websockify \
    # Python
    python3 \
    py3-pip \
    # Build tools
    gcc \
    musl-dev \
    python3-dev \
    linux-headers \
    # System
    dbus \
    ttf-freefont \
    ttf-dejavu \
    bash \
    wget \
    curl \
    # Clean cache
    && rm -rf /var/cache/apk/*

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

# Set environment variables
ENV DISPLAY=:99
ENV CHROMIUM_FLAGS="--no-sandbox --disable-dev-shm-usage --disable-gpu --ignore-certificate-errors --allow-insecure-localhost --disable-web-security --test-type"
ENV HOME=/tmp
ENV PORT=10000
ENV PATH="/app/venv/bin:$PATH"
ENV PYTHONPATH="/app/venv/lib/python3.12/site-packages"

# Create startup script that runs everything on PORT 10000
RUN echo '#!/bin/bash' > /app/start.sh && \
    echo 'set -e' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo 'echo "=========================================="' >> /app/start.sh && \
    echo 'echo "🚀 Starting RDP Browser (Render Compatible)"' >> /app/start.sh && \
    echo 'echo "=========================================="' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Export environment' >> /app/start.sh && \
    echo 'export PATH="/app/venv/bin:$PATH"' >> /app/start.sh && \
    echo 'export DISPLAY=:99' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Get the external URL from Render' >> /app/start.sh && \
    echo 'if [ -n "$RENDER_EXTERNAL_URL" ]; then' >> /app/start.sh && \
    echo '    EXTERNAL_URL="$RENDER_EXTERNAL_URL"' >> /app/start.sh && \
    echo 'else' >> /app/start.sh && \
    echo '    EXTERNAL_URL="http://localhost:10000"' >> /app/start.sh && \
    echo 'fi' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start Xvfb' >> /app/start.sh && \
    echo 'Xvfb :99 -screen 0 1280x1024x24 -ac +extension GLX +render -noreset >/tmp/xvfb.log 2>&1 &' >> /app/start.sh && \
    echo 'sleep 3' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start fluxbox' >> /app/start.sh && \
    echo 'fluxbox >/tmp/fluxbox.log 2>&1 &' >> /app/start.sh && \
    echo 'sleep 2' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start browser with target URL' >> /app/start.sh && \
    echo 'echo "Starting browser with target URL..."' >> /app/start.sh && \
    echo 'chromium-browser $CHROMIUM_FLAGS \' >> /app/start.sh && \
    echo '  --window-size=1280,1024 \' >> /app/start.sh && \
    echo '  --window-position=0,0 \' >> /app/start.sh && \
    echo '  --app="https://literate-cod-g474wqj4x9f59p.github.dev/?editor=jupyter" \' >> /app/start.sh && \
    echo '  --display=:99 >/tmp/chrome.log 2>&1 &' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start VNC server on RENDER INTERNAL PORT' >> /app/start.sh && \
    echo '# Render only allows traffic on $PORT (10000)' >> /app/start.sh && \
    echo '# So we run VNC internally and proxy through Flask' >> /app/start.sh && \
    echo 'x11vnc \' >> /app/start.sh && \
    echo '  -display :99 \' >> /app/start.sh && \
    echo '  -forever \' >> /app/start.sh && \
    echo '  -shared \' >> /app/start.sh && \
    echo '  -nopw \' >> /app/start.sh && \
    echo '  -listen 127.0.0.1 \' >> /app/start.sh && \
    echo '  -rfbport 5900 \' >> /app/start.sh && \
    echo '  -noxdamage >/tmp/vnc.log 2>&1 &' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start websockify proxy on localhost' >> /app/start.sh && \
    echo 'websockify --web /usr/share/novnc 127.0.0.1:6080 127.0.0.1:5900 >/tmp/websockify.log 2>&1 &' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Wait for services to start' >> /app/start.sh && \
    echo 'sleep 5' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo 'echo "✅ Services started!"' >> /app/start.sh && \
    echo 'echo "🌐 External URL: $EXTERNAL_URL"' >> /app/start.sh && \
    echo 'echo "🎯 Target: https://literate-cod-g474wqj4x9f59p.github.dev/?editor=jupyter"' >> /app/start.sh && \
    echo 'echo "=========================================="' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start Flask control panel (this is what Render sees on port 10000)' >> /app/start.sh && \
    echo 'cd /app && python3 rdp-browser.py' >> /app/start.sh && \
    chmod +x /app/start.sh

# Set permissions
RUN chown -R browseruser:browseruser /app

# Switch to non-root user
USER browseruser

# Expose ONLY port 10000 (Render requirement)
EXPOSE 10000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:10000/health || exit 1

# Start the service
CMD ["/bin/bash", "/app/start.sh"]
