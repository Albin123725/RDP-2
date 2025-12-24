FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

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

# Set up VNC
RUN mkdir -p /root/.vnc && \
    echo "password" | vncpasswd -f > /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd

# Create startup script
RUN echo '#!/bin/bash\n\
unset SESSION_MANAGER\n\
unset DBUS_SESSION_BUS_ADDRESS\n\
exec startxfce4 &' > /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

# Configure noVNC
RUN ln -s /usr/share/novnc/vnc_lite.html /usr/share/novnc/index.html

# Start services
EXPOSE 80
CMD ["bash", "-c", "vncserver :1 -geometry 1280x720 -depth 24 && websockify -D --web=/usr/share/novnc/ 80 localhost:5901 && tail -f /dev/null"]
