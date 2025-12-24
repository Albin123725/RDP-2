# 🚀 Fast RDP Desktop with Browser
FROM alpine:edge

# Install packages
RUN apk add --no-cache --update \
    # X server
    xvfb \
    # Use TurboVNC for better performance
    turbovnc \
    # Lightweight desktop
    openbox \
    # Browser (Firefox ESR for stability)
    firefox-esr \
    # Web VNC
    novnc \
    websockify \
    # Fonts
    ttf-freefont \
    # Utilities
    xterm \
    # Clean
    && rm -rf /var/cache/apk/*

# Create user
RUN adduser -D -u 1000 user && \
    mkdir -p /home/user/.vnc && \
    echo "password123" | vncpasswd -f > /home/user/.vnc/passwd && \
    chown -R user:user /home/user && \
    chmod 600 /home/user/.vnc/passwd

# Create Openbox autostart
RUN mkdir -p /home/user/.config/openbox && \
    echo '#!/bin/sh' > /home/user/.config/openbox/autostart && \
    echo '' >> /home/user/.config/openbox/autostart && \
    echo '# Start Firefox' >> /home/user/.config/openbox/autostart && \
    echo 'firefox-esr --no-remote --new-instance &' >> /home/user/.config/openbox/autostart && \
    echo '' >> /home/user/.config/openbox/autostart && \
    echo '# Start terminal' >> /home/user/.config/openbox/autostart && \
    echo 'xterm &' >> /home/user/.config/openbox/autostart && \
    chown -R user:user /home/user/.config

# Create startup script
RUN echo '#!/bin/sh' > /start.sh && \
    echo '' >> /start.sh && \
    echo '# Set display' >> /start.sh && \
    echo 'export DISPLAY=:1' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start TurboVNC server' >> /start.sh && \
    echo '/usr/bin/vncserver :1 -geometry 1280x1024 -depth 24 -localhost no -SecurityTypes None -xstartup /usr/bin/openbox-session' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Wait for VNC to start' >> /start.sh && \
    echo 'sleep 3' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start noVNC web interface' >> /start.sh && \
    echo 'websockify --web /usr/share/novnc 10000 localhost:5901 &' >> /start.sh && \
    echo '' >> /start.sh && \
    echo 'echo "🚀 Fast RDP Ready!"' >> /start.sh && \
    echo 'echo "🌐 Connect: http://[HOST]:10000/vnc.html"' >> /start.sh && \
    echo 'echo "🔑 Password: password123"' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Keep container running' >> /start.sh && \
    echo 'tail -f /dev/null' >> /start.sh && \
    chmod +x /start.sh

USER user
WORKDIR /home/user
EXPOSE 10000
CMD ["/start.sh"]
