# Use Alpine Linux for minimal size
FROM alpine:edge

# Install only essential packages
RUN apk add --no-cache \
    # X11 server and minimal desktop
    xvfb \
    x11vnc \
    fluxbox \
    
    # Web browser (choose one)
    firefox-esr \
    # OR for even lighter: lynx (text-only) or dillo (very light)
    
    # RDP server
    xrdp \
    
    # Basic tools
    bash \
    sudo \
    curl \
    
    # Fonts
    ttf-freefont \
    fontconfig \
    
    # Clean up
    && rm -rf /var/cache/apk/*

# Create a non-root user
RUN adduser -D -u 1000 browseruser && \
    echo "browseruser:password" | chpasswd && \
    echo "browseruser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Set up X11 and VNC
RUN mkdir -p /home/browseruser/.vnc && \
    echo "password" | vncpasswd -f > /home/browseruser/.vnc/passwd && \
    chmod 600 /home/browseruser/.vnc/passwd && \
    chown -R browseruser:browseruser /home/browseruser

# Set up xrdp
RUN sed -i 's/port=3389/port=3390/g' /etc/xrdp/xrdp.ini && \
    sed -i 's/allow_root=true/allow_root=false/g' /etc/xrdp/sesman.ini && \
    echo "startwm.sh" > /etc/xrdp/startwm.sh && \
    chmod +x /etc/xrdp/startwm.sh

# Create startup script
RUN echo '#!/bin/bash' > /start.sh && \
    echo '# Start Xvfb on display :99' >> /start.sh && \
    echo 'Xvfb :99 -screen 0 1024x768x24 -ac +extension GLX +render -noreset &' >> /start.sh && \
    echo '# Start Fluxbox (lightweight window manager)' >> /start.sh && \
    echo 'DISPLAY=:99 fluxbox &' >> /start.sh && \
    echo '# Start Firefox (maximized)' >> /start.sh && \
    echo 'DISPLAY=:99 firefox --kiosk --private-window https://www.google.com &' >> /start.sh && \
    echo '# Start xrdp' >> /start.sh && \
    echo 'xrdp-sesman &' >> /start.sh && \
    echo 'xrdp &' >> /start.sh && \
    echo '# Start VNC server (optional)' >> /start.sh && \
    echo 'x11vnc -display :99 -forever -noxdamage -repeat -shared -nopw &' >> /start.sh && \
    echo '# Keep container running' >> /start.sh && \
    echo 'tail -f /dev/null' >> /start.sh && \
    chmod +x /start.sh

# Switch to user
USER browseruser
WORKDIR /home/browseruser

# Expose ports
EXPOSE 3389 3390 5900

# Start everything
CMD ["/start.sh"]
