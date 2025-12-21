FROM debian:bullseye-slim

# Set non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies with cleanup
RUN apt-get update && \
    apt-get install -y \
    # Core desktop
    xfce4 xfce4-terminal xfce4-goodies \
    # Browser and tools
    firefox-esr nano procps net-tools \
    # VNC and display
    tightvncserver novnc websockify \
    # X11 and display
    x11-apps x11-utils xserver-xorg-core \
    dbus-x11 xfonts-base xfonts-100dpi xfonts-75dpi \
    # System utilities
    wget curl git \
    # Additional fonts
    fonts-wqy-zenhei fonts-liberation \
    && rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /root/.vnc /root/.config/xfce4/xfconf/xfce-perchannel-xml

# Set up VNC password and xstartup
RUN echo 'Albin4242' | vncpasswd -f > /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd

# Create xstartup script
RUN echo '#!/bin/bash' > /root/.vnc/xstartup && \
    echo 'unset SESSION_MANAGER' >> /root/.vnc/xstartup && \
    echo 'unset DBUS_SESSION_BUS_ADDRESS' >> /root/.vnc/xstartup && \
    echo '' >> /root/.vnc/xstartup && \
    echo '# Start XFCE' >> /root/.vnc/xstartup && \
    echo 'startxfce4 &' >> /root/.vnc/xstartup && \
    chmod 755 /root/.vnc/xstartup

# Create start.sh script
RUN echo '#!/bin/bash' > /start.sh && \
    echo '' >> /start.sh && \
    echo '# Create necessary directories' >> /start.sh && \
    echo 'mkdir -p /tmp/.X11-unix /var/run/dbus' >> /start.sh && \
    echo 'chmod 1777 /tmp/.X11-unix' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start DBus' >> /start.sh && \
    echo 'dbus-daemon --system --fork' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Set environment variables' >> /start.sh && \
    echo 'export DISPLAY=:1' >> /start.sh && \
    echo 'export PULSE_SERVER=tcp:localhost:4713' >> /start.sh && \
    echo 'export LANG=en_US.UTF-8' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Kill any existing VNC server on display :1' >> /start.sh && \
    echo 'vncserver -kill :1 2>/dev/null || true' >> /start.sh && \
    echo 'rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null || true' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start VNC server with larger screen' >> /start.sh && \
    echo 'vncserver :1 -geometry 1440x900 -depth 24 -localhost no' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Wait for VNC to start' >> /start.sh && \
    echo 'sleep 2' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start noVNC on all interfaces (0.0.0.0) for Render.com' >> /start.sh && \
    echo 'websockify --web=/usr/share/novnc 0.0.0.0:8900 localhost:5901' >> /start.sh && \
    chmod +x /start.sh

# Expose port for Render
EXPOSE 8900

# Health check (optional)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8900/ || exit 1

# Set working directory
WORKDIR /root

# Start the service
CMD ["/bin/bash", "/start.sh"]
