FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV USER=root
ENV HOME=/root

# Install XFCE, VNC, and noVNC
RUN apt-get update && apt-get install -y \
    xfce4 \
    xfce4-goodies \
    tightvncserver \
    novnc \
    websockify \
    firefox \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Set up VNC with proper user environment
RUN mkdir -p /root/.vnc && \
    echo "password" | vncpasswd -f > /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd

# Create startup script
RUN echo '#!/bin/bash\n\
unset SESSION_MANAGER\n\
unset DBUS_SESSION_BUS_ADDRESS\n\
export USER=root\n\
export HOME=/root\n\
exec startxfce4 &' > /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

# Configure noVNC
RUN ln -s /usr/share/novnc/vnc_lite.html /usr/share/novnc/index.html

# Set working directory
WORKDIR /root

# Start services (noVNC on port 80 for Render compatibility)
CMD ["bash", "-c", "vncserver :1 -geometry 1280x720 -depth 24 && websockify -D --web=/usr/share/novnc/ 80 localhost:5901 && tail -f /dev/null"]
