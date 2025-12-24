# 🚀 Ultra-Minimal RDP + Browser ONLY
# No Flask, no control panel, just RDP desktop with browser
FROM alpine:edge

# Install ONLY what's needed for RDP + Browser
RUN apk add --no-cache --update \
    # X server
    xvfb \
    x11vnc \
    # Window manager (lightest possible)
    jwm \
    # Browser (Firefox - works better in containers)
    firefox \
    # VNC web interface
    novnc \
    websockify \
    # Terminal (for debugging if needed)
    xterm \
    # System
    dbus \
    ttf-freefont \
    bash \
    # Clean cache
    && rm -rf /var/cache/apk/*

# Create user
RUN adduser -D -u 1000 user && \
    mkdir -p /home/user/.config && \
    chown -R user:user /home/user

# Create simple JWM config (minimal desktop)
RUN mkdir -p /home/user/.jwm && \
    echo '<?xml version="1.0"?>' > /home/user/.jwm/jwmrc && \
    echo '<JWM>' >> /home/user/.jwm/jwmrc && \
    echo '  <RootMenu onroot="1">' >> /home/user/.jwm/jwmrc && \
    echo '    <Program label="Firefox Browser">firefox</Program>' >> /home/user/.jwm/jwmrc && \
    echo '    <Program label="Terminal">xterm</Program>' >> /home/user/.jwm/jwmrc && \
    echo '    <Separator/>' >> /home/user/.jwm/jwmrc && \
    echo '    <Program label="Exit">exit</Program>' >> /home/user/.jwm/jwmrc && \
    echo '  </RootMenu>' >> /home/user/.jwm/jwmrc && \
    echo '  <Tray x="0" y="-1" autohide="off">' >> /home/user/.jwm/jwmrc && \
    echo '    <Clock format="%H:%M"/></Tray>' >> /home/user/.jwm/jwmrc && \
    echo '</JWM>' >> /home/user/.jwm/jwmrc && \
    chown -R user:user /home/user/.jwm

# Create startup script
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'set -e' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Set display' >> /start.sh && \
    echo 'export DISPLAY=:99' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start Xvfb (virtual display)' >> /start.sh && \
    echo 'Xvfb :99 -screen 0 1280x1024x24 -ac +extension RANDR +extension GLX -nolisten tcp -noreset &' >> /start.sh && \
    echo 'sleep 2' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Verify X server is working' >> /start.sh && \
    echo 'if ! xdpyinfo -display :99 >/dev/null 2>&1; then' >> /start.sh && \
    echo '    echo "ERROR: X server failed to start"' >> /start.sh && \
    echo '    exit 1' >> /start.sh && \
    echo 'fi' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start JWM window manager' >> /start.sh && \
    echo 'jwm -display :99 &' >> /start.sh && \
    echo 'sleep 1' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start VNC server' >> /start.sh && \
    echo 'x11vnc \' >> /start.sh && \
    echo '  -display :99 \' >> /start.sh && \
    echo '  -forever \' >> /start.sh && \
    echo '  -shared \' >> /start.sh && \
    echo '  -nopw \' >> /start.sh && \
    echo '  -listen 0.0.0.0 \' >> /start.sh && \
    echo '  -rfbport 5900 \' >> /start.sh && \
    echo '  -noxdamage \' >> /start.sh && \
    echo '  -xkb &' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start noVNC web interface on port 8080' >> /start.sh && \
    echo 'websockify --web /usr/share/novnc 8080 localhost:5900 &' >> /start.sh && \
    echo '' >> /start.sh && \
    echo 'echo "=========================================="' >> /start.sh && \
    echo 'echo "🚀 RDP + Browser Ready!"' >> /start.sh && \
    echo 'echo ""' >> /start.sh && \
    echo 'echo "📺 Access via:"' >> /start.sh && \
    echo 'echo "1. Web VNC: http://[HOST]:8080/vnc.html"' >> /start.sh && \
    echo 'echo "2. Direct VNC: [HOST]:5900 (no password)"' >> /start.sh && \
    echo 'echo ""' >> /start.sh && \
    echo 'echo "🖥️  Desktop includes:"' >> /start.sh && \
    echo 'echo "• Firefox Browser"' >> /start.sh && \
    echo 'echo "• Right-click menu for apps"' >> /start.sh && \
    echo 'echo "• Clean minimal desktop"' >> /start.sh && \
    echo 'echo "=========================================="' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Keep container running' >> /start.sh && \
    echo 'tail -f /dev/null' >> /start.sh && \
    chmod +x /start.sh

# Switch to user
USER user

# Expose ports
EXPOSE 5900 8080

# Start
CMD ["/bin/bash", "/start.sh"]
