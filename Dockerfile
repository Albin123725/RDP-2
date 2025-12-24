# 🚀 Pure RDP + Browser - Render Fixed
FROM alpine:edge

# Install packages as root
RUN apk add --no-cache --update \
    # X Server with minimal dependencies
    xvfb \
    x11vnc \
    # Window manager
    fluxbox \
    # Browser
    firefox \
    # VNC
    novnc \
    websockify \
    # Fonts
    ttf-freefont \
    # Clean
    && rm -rf /var/cache/apk/*

# Create X11 directory with correct permissions
RUN mkdir -p /tmp/.X11-unix && \
    chmod 1777 /tmp/.X11-unix && \
    chown root:root /tmp/.X11-unix

# Create user
RUN adduser -D -u 1000 user

# Create simple fluxbox config
RUN mkdir -p /home/user/.fluxbox && \
    echo '[begin] (fluxbox)' > /home/user/.fluxbox/menu && \
    echo '  [exec] (Firefox) {firefox}' >> /home/user/.fluxbox/menu && \
    echo '  [separator]' >> /home/user/.fluxbox/menu && \
    echo '  [exit] (Exit)' >> /home/user/.fluxbox/menu && \
    echo '[end]' >> /home/user/.fluxbox/menu && \
    chown -R user:user /home/user

# Simple startup script (no complex checks)
RUN echo '#!/bin/sh' > /start.sh && \
    echo '' >> /start.sh && \
    echo '# Fix X11 permissions' >> /start.sh && \
    echo 'mkdir -p /tmp/.X11-unix' >> /start.sh && \
    echo 'chmod 1777 /tmp/.X11-unix' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start Xvfb with simple settings' >> /start.sh && \
    echo 'Xvfb :99 -screen 0 1024x768x16 -ac -noreset &' >> /start.sh && \
    echo 'sleep 3' >> /start.sh && \
    echo '' >> /start.sh && \
    echo 'export DISPLAY=:99' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start fluxbox' >> /start.sh && \
    echo 'fluxbox &' >> /start.sh && \
    echo 'sleep 2' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start Firefox in background' >> /start.sh && \
    echo 'firefox --display=:99 &' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start VNC (skip xkb to avoid warnings)' >> /start.sh && \
    echo 'x11vnc -display :99 -forever -shared -nopw -listen 0.0.0.0 -rfbport 5900 -noxdamage -noxkb &' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start noVNC web interface' >> /start.sh && \
    echo 'websockify --web /usr/share/novnc 10000 localhost:5900 &' >> /start.sh && \
    echo '' >> /start.sh && \
    echo 'echo "✅ RDP Ready on port 10000"' >> /start.sh && \
    echo 'echo "🌐 Connect: http://[HOST]:10000/vnc.html"' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Keep container running' >> /start.sh && \
    echo 'tail -f /dev/null' >> /start.sh && \
    chmod +x /start.sh

USER user
EXPOSE 10000
CMD ["/start.sh"]
