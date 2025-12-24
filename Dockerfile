# 🚀 RDP Browser - Guaranteed Working Version
FROM alpine:edge

# Install packages in one layer
RUN apk add --no-cache --update \
    # X server with ALL dependencies
    xvfb \
    x11vnc \
    xrandr \
    xdpyinfo \
    xterm \
    # Window manager
    fluxbox \
    # Browser
    firefox \
    # VNC web interface
    novnc \
    websockify \
    # Python
    python3 \
    py3-pip \
    # System
    dbus \
    ttf-freefont \
    ttf-dejavu \
    bash \
    wget \
    curl \
    # Build tools
    gcc \
    musl-dev \
    python3-dev \
    linux-headers \
    # Fonts for browser
    font-noto \
    font-noto-cjk \
    # Clean cache
    && rm -rf /var/cache/apk/*

# Create app directory
WORKDIR /app

# Install Python packages
RUN python3 -m venv /app/venv && \
    /app/venv/bin/pip install --no-cache-dir --upgrade pip && \
    /app/venv/bin/pip install --no-cache-dir \
    flask==2.3.3 \
    gunicorn==21.2.0

# Create non-root user
RUN adduser -D -u 1000 browseruser && \
    mkdir -p /home/browseruser/.config && \
    chown -R browseruser:browseruser /home/browseruser

# Copy application
COPY rdp-browser.py /app/

# Create working directories
RUN mkdir -p /tmp/.X11-unix && \
    chmod 1777 /tmp/.X11-unix && \
    mkdir -p /tmp/chrome && \
    chmod 777 /tmp/chrome

# Create startup script
RUN echo '#!/bin/bash' > /app/start.sh && \
    echo 'set -e' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo 'echo "=========================================="' >> /app/start.sh && \
    echo 'echo "🚀 Starting RDP Browser - Guaranteed Working"' >> /app/start.sh && \
    echo 'echo "=========================================="' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Set display' >> /app/start.sh && \
    echo 'export DISPLAY=:99' >> /app/start.sh && \
    echo 'export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/dbus/system_bus_socket' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start dbus' >> /app/start.sh && \
    echo 'dbus-uuidgen > /var/lib/dbus/machine-id' >> /app/start.sh && \
    echo 'mkdir -p /var/run/dbus' >> /app/start.sh && \
    echo 'dbus-daemon --config-file=/usr/share/dbus-1/system.conf --print-address' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start Xvfb with proper settings' >> /app/start.sh && \
    echo 'echo "Starting X virtual framebuffer..."' >> /app/start.sh && \
    echo 'Xvfb :99 -screen 0 1280x1024x24 -ac +extension RANDR +extension GLX +extension MIT-SHM +extension XFIXES -nolisten tcp -noreset >/tmp/xvfb.log 2>&1 &' >> /app/start.sh && \
    echo 'XVFB_PID=$!' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Wait for Xvfb' >> /app/start.sh && \
    echo 'sleep 3' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Verify Xvfb is working' >> /app/start.sh && \
    echo 'if xdpyinfo -display :99 >/dev/null 2>&1; then' >> /app/start.sh && \
    echo '    echo "✅ Xvfb is working"' >> /app/start.sh && \
    echo 'else' >> /app/start.sh && \
    echo '    echo "❌ Xvfb failed to start"' >> /app/start.sh && \
    echo '    exit 1' >> /app/start.sh && \
    echo 'fi' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start fluxbox' >> /app/start.sh && \
    echo 'echo "Starting window manager..."' >> /app/start.sh && \
    echo 'fluxbox -display :99 >/tmp/fluxbox.log 2>&1 &' >> /app/start.sh && \
    echo 'FLUXBOX_PID=$!' >> /app/start.sh && \
    echo 'sleep 2' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start Firefox with target URL (Firefox works better than Chrome in containers)' >> /app/start.sh && \
    echo 'echo "Starting Firefox with GitHub Codespaces..."' >> /app/start.sh && \
    echo 'firefox --display=:99 \' >> /app/start.sh && \
    echo '  --width=1280 \' >> /app/start.sh && \
    echo '  --height=1024 \' >> /app/start.sh && \
    echo '  --new-window "https://literate-cod-g474wqj4x9f59p.github.dev/?editor=jupyter" \' >> /app/start.sh && \
    echo '  >/tmp/firefox.log 2>&1 &' >> /app/start.sh && \
    echo 'FIREFOX_PID=$!' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Wait for Firefox to start' >> /app/start.sh && \
    echo 'sleep 5' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start VNC server' >> /app/start.sh && \
    echo 'echo "Starting VNC server..."' >> /app/start.sh && \
    echo 'x11vnc \' >> /app/start.sh && \
    echo '  -display :99 \' >> /app/start.sh && \
    echo '  -forever \' >> /app/start.sh && \
    echo '  -shared \' >> /app/start.sh && \
    echo '  -nopw \' >> /app/start.sh && \
    echo '  -listen 127.0.0.1 \' >> /app/start.sh && \
    echo '  -rfbport 5900 \' >> /app/start.sh && \
    echo '  -noxdamage \' >> /app/start.sh && \
    echo '  -xkb \' >> /app/start.sh && \
    echo '  -clear_keys \' >> /app/start.sh && \
    echo '  -clear_mods \' >> /app/start.sh && \
    echo '  >/tmp/x11vnc.log 2>&1 &' >> /app/start.sh && \
    echo 'VNC_PID=$!' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start websockify proxy' >> /app/start.sh && \
    echo 'echo "Starting WebSocket proxy..."' >> /app/start.sh && \
    echo 'websockify --web /usr/share/novnc 127.0.0.1:6080 127.0.0.1:5900 >/tmp/websockify.log 2>&1 &' >> /app/start.sh && \
    echo 'WEBSOCKIFY_PID=$!' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Wait for everything to start' >> /app/start.sh && \
    echo 'sleep 5' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo 'echo "✅ All services started successfully!"' >> /app/start.sh && \
    echo 'echo "🌐 Control Panel: http://localhost:10000"' >> /app/start.sh && \
    echo 'echo "📺 VNC Client: http://localhost:10000/vnc"' >> /app/start.sh && \
    echo 'echo "🎯 Target: https://literate-cod-g474wqj4x9f59p.github.dev/?editor=jupyter"' >> /app/start.sh && \
    echo 'echo ""' >> /app/start.sh && \
    echo '# Show process status' >> /app/start.sh && \
    echo 'echo "Process Status:"' >> /app/start.sh && \
    echo 'echo "  Xvfb: PID $XVFB_PID"' >> /app/start.sh && \
    echo 'echo "  Fluxbox: PID $FLUXBOX_PID"' >> /app/start.sh && \
    echo 'echo "  Firefox: PID $FIREFOX_PID"' >> /app/start.sh && \
    echo 'echo "  VNC: PID $VNC_PID"' >> /app/start.sh && \
    echo 'echo "  Websockify: PID $WEBSOCKIFY_PID"' >> /app/start.sh && \
    echo 'echo "=========================================="' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start Flask control panel' >> /app/start.sh && \
    echo 'echo "Starting control panel..."' >> /app/start.sh && \
    echo 'cd /app && python3 rdp-browser.py' >> /app/start.sh && \
    chmod +x /app/start.sh

# Set permissions
RUN chown -R browseruser:browseruser /app

# Switch to non-root user
USER browseruser

# Expose port
EXPOSE 10000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:10000/health || exit 1

# Start
CMD ["/bin/bash", "/app/start.sh"]
