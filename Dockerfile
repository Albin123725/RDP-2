FROM debian:bullseye-slim

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    USER=root \
    HOME=/root \
    DISPLAY=:1 \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Install dependencies
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
    wget curl git locales \
    # Additional fonts
    fonts-wqy-zenhei fonts-liberation \
    # Fix locale issues
    locales-all \
    && rm -rf /var/lib/apt/lists/*

# Generate locale
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8

# Create necessary directories
RUN mkdir -p /root/.vnc /tmp/.X11-unix /var/run/dbus

# Set up VNC password
RUN echo 'Albin4242' | vncpasswd -f > /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd

# Create xstartup script
RUN echo '#!/bin/bash' > /root/.vnc/xstartup && \
    echo 'unset SESSION_MANAGER' >> /root/.vnc/xstartup && \
    echo 'unset DBUS_SESSION_BUS_ADDRESS' >> /root/.vnc/xstartup && \
    echo '' >> /root/.vnc/xstartup && \
    echo '# Start XFCE' >> /root/.vnc/xstartup && \
    echo 'exec startxfce4' >> /root/.vnc/xstartup && \
    chmod 755 /root/.vnc/xstartup

# Create start script
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'set -e' >> /start.sh && \
    echo '' >> /start.sh && \
    echo 'echo "=== Starting XFCE Desktop on Render.com ==="' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Set environment variables' >> /start.sh && \
    echo 'export USER=root' >> /start.sh && \
    echo 'export HOME=/root' >> /start.sh && \
    echo 'export DISPLAY=:1' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Create necessary directories' >> /start.sh && \
    echo 'mkdir -p /tmp/.X11-unix /var/run/dbus' >> /start.sh && \
    echo 'chmod 1777 /tmp/.X11-unix' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start DBus' >> /start.sh && \
    echo 'echo "Starting DBus..."' >> /start.sh && \
    echo 'dbus-daemon --system --fork' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Clean up any existing VNC session' >> /start.sh && \
    echo 'echo "Cleaning up previous VNC sessions..."' >> /start.sh && \
    echo 'rm -rf /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null || true' >> /start.sh && \
    echo 'rm -rf /tmp/.X11-unix/X1 2>/dev/null || true' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start VNC server' >> /start.sh && \
    echo 'echo "Starting VNC server on display :1..."' >> /start.sh && \
    echo 'vncserver :1 -geometry 1440x900 -depth 24 -localhost no -alwaysshared -SecurityTypes VncAuth' >> /start.sh && \
    echo '' >> /start.sh && \
    echo 'echo "VNC server started on port 5901"' >> /start.sh && \
    echo 'echo "VNC Password: Albin4242"' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Wait a moment for VNC to stabilize' >> /start.sh && \
    echo 'sleep 3' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Check if VNC is running' >> /start.sh && \
    echo 'if pgrep -x "Xvnc" > /dev/null; then' >> /start.sh && \
    echo '    echo "VNC server is running"' >> /start.sh && \
    echo 'else' >> /start.sh && \
    echo '    echo "ERROR: VNC server failed to start"' >> /start.sh && \
    echo '    exit 1' >> /start.sh && \
    echo 'fi' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start noVNC' >> /start.sh && \
    echo 'echo "Starting noVNC web interface on port 8900..."' >> /start.sh && \
    echo 'echo "=== Desktop is now accessible ==="' >> /start.sh && \
    echo 'echo "Web URL: https://${RENDER_EXTERNAL_HOSTNAME:-localhost}:8900/vnc.html"' >> /start.sh && \
    echo 'echo "Password: Albin4242"' >> /start.sh && \
    echo 'echo "======================================"' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start websockify with novnc' >> /start.sh && \
    echo 'exec websockify --web=/usr/share/novnc 0.0.0.0:8900 localhost:5901' >> /start.sh && \
    chmod +x /start.sh

# Expose port
EXPOSE 8900

# Set working directory
WORKDIR /root

# Start the service
CMD ["/bin/bash", "/start.sh"]
