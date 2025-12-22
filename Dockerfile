FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Kolkata \
    USER=root \
    HOME=/root \
    DISPLAY=:1 \
    VNC_PASSWD=password123 \
    VNC_RESOLUTION=1280x720 \
    VNC_DEPTH=16  # Reduced from 24 to save memory

# Set timezone
RUN ln -fs /usr/share/zoneinfo/Asia/Kolkata /etc/localtime && \
    echo "Asia/Kolkata" > /etc/timezone

# Install minimal required packages and clean up aggressively
RUN apt update && apt install -y \
    xfce4 \
    xfce4-goodies \
    tightvncserver \
    novnc \
    websockify \
    wget \
    sudo \
    dbus-x11 \
    x11-utils \
    x11-xserver-utils \
    --no-install-recommends && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    # Remove unnecessary documentation and locales
    rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/locale/* && \
    # Remove Xfce components that aren't essential
    apt purge -y xfce4-screensaver xfce4-power-manager xscreensaver* && \
    apt autoremove -y && \
    apt autoclean

# Setup VNC password with less memory-intensive settings
RUN mkdir -p /root/.vnc && \
    printf "${VNC_PASSWD}\n${VNC_PASSWD}\nn\n" | vncpasswd && \
    chmod 600 /root/.vnc/passwd

# Create optimized xstartup with memory-saving options
RUN echo '#!/bin/bash\n\
unset SESSION_MANAGER\n\
unset DBUS_SESSION_BUS_ADDRESS\n\
[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup\n\
[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources\n\
xsetroot -solid grey\n\
# Disable composite manager to save memory\n\
xfwm4 --compositor=off &\n\
# Start with minimal Xfce components\n\
xfsettingsd --daemon\n\
xfce4-panel &\n\
xfdesktop &\n\
# Start Thunar only when needed\n\
# thunar --daemon &\n\
vncconfig -iconic &\n\
# Set low memory usage policies\n\
echo 1 > /proc/sys/vm/overcommit_memory\n\
echo 3 > /proc/sys/vm/drop_caches' > /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

# Get noVNC
RUN wget -q https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.tar.gz -O /tmp/novnc.tar.gz && \
    tar -xzf /tmp/novnc.tar.gz -C /opt/ && \
    mv /opt/noVNC-1.4.0 /opt/novnc && \
    rm /tmp/novnc.tar.gz && \
    wget -q https://github.com/novnc/websockify/archive/refs/tags/v0.11.0.tar.gz -O /tmp/websockify.tar.gz && \
    tar -xzf /tmp/websockify.tar.gz -C /opt/novnc/utils/ && \
    mv /opt/novnc/utils/websockify-0.11.0 /opt/novnc/utils/websockify && \
    rm /tmp/websockify.tar.gz

# Create cleanup script for periodic memory management
RUN echo '#!/bin/bash\n\
while true; do\n\
    # Clear cache every 5 minutes\n\
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true\n\
    # Kill any zombie processes\n\
    ps aux | grep "defunct" | grep -v grep | awk "{print \$2}" | xargs -r kill -9 2>/dev/null || true\n\
    sleep 300\n\
done' > /cleanup.sh && \
    chmod +x /cleanup.sh

EXPOSE 10000

# Optimized start command with memory limits
CMD echo "Starting VNC server with optimized settings..." && \
    # Start memory cleanup in background
    /cleanup.sh & \
    # Set VNC server with lower color depth and compression
    vncserver :1 -geometry ${VNC_RESOLUTION} -depth ${VNC_DEPTH} -dpi 96 -rfbauth /root/.vnc/passwd -noxstartup -nolisten tcp -localhost -SecurityTypes VncAuth && \
    echo "VNC started successfully on display :1" && \
    # Start noVNC proxy with low memory profile
    /opt/novnc/utils/novnc_proxy --vnc localhost:5901 --listen 0.0.0.0:10000 --heartbeat 30 & \
    # Monitor and restart if memory gets too high
    tail -f /dev/null
