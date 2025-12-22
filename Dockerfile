# Dockerfile - All-in-one lightweight VNC/RDP desktop for Render
FROM ubuntu:22.04

# Set non-interactive environment
ENV DEBIAN_FRONTEND=noninteractive \
    VNC_PASSWORD=password \
    VNC_RESOLUTION=1280x720 \
    VNC_DEPTH=24 \
    DISPLAY=:1 \
    LANG=en_US.UTF-8

# Install everything in one layer to reduce image size
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core system
    sudo \
    curl \
    wget \
    gnupg2 \
    software-properties-common \
    ca-certificates \
    # VNC and display
    tigervnc-standalone-server \
    tigervnc-common \
    xvfb \
    x11vnc \
    # Lightweight desktop (XFCE)
    xfce4 \
    xfce4-terminal \
    xfce4-goodies \
    xfce4-taskmanager \
    thunar \
    mousepad \
    # Browser and utilities
    firefox \
    htop \
    nano \
    git \
    python3 \
    python3-pip \
    # RDP support (optional)
    xrdp \
    # Fonts and themes
    fonts-noto \
    fonts-noto-cjk \
    gtk2-engines-murrine \
    gtk2-engines-pixbuf \
    # System tools
    dbus-x11 \
    pulseaudio \
    # Chinese input support (remove if not needed)
    fcitx \
    fcitx-googlepinyin \
    fcitx-config-gtk \
    # Clean up
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install noVNC from source
RUN git clone https://github.com/novnc/noVNC.git /opt/novnc \
    && git clone https://github.com/novnc/websockify /opt/novnc/utils/websockify \
    && cd /opt/novnc && npm install \
    && ln -s /opt/novnc/vnc.html /opt/novnc/index.html \
    && rm -rf /opt/novnc/.git /opt/novnc/utils/websockify/.git

# Create VNC directory and set password
RUN mkdir -p /tmp/.X11-unix /var/run/dbus /root/.vnc /root/.config/xfce4 \
    && echo "$VNC_PASSWORD" | vncpasswd -f > /root/.vnc/passwd \
    && chmod 600 /root/.vnc/passwd

# Configure XFCE (minimal config)
RUN echo "#!/bin/sh\nstartxfce4" > /root/.vnc/xstartup \
    && echo "xfce4-session" > /root/.xsession \
    && chmod +x /root/.vnc/xstartup /root/.xsession

# Create startup script that handles everything
RUN echo '#!/bin/bash\n\
# Set VNC password from environment\n\
echo "$VNC_PASSWORD" | vncpasswd -f > /root/.vnc/passwd\n\
chmod 600 /root/.vnc/passwd\n\
\n\
# Kill any existing VNC sessions\n\
vncserver -kill :1 2>/dev/null || true\n\
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1\n\
\n\
# Start Xvfb (virtual framebuffer)\n\
Xvfb :0 -screen 0 ${VNC_RESOLUTION}x${VNC_DEPTH} &\n\
\n\
# Wait for Xvfb\n\
sleep 2\n\
\n\
# Set display\n\
export DISPLAY=:0\n\
\n\
# Start XFCE\n\
startxfce4 &\n\
\n\
# Start VNC server\n\
x11vnc -display :0 -noxdamage -forever -shared -rfbauth /root/.vnc/passwd -rfbport 5901 &\n\
\n\
# Start noVNC\n\
/opt/novnc/utils/novnc_proxy --vnc localhost:5901 --listen 0.0.0.0:8080 &\n\
\n\
# Start RDP server (optional)\n\
# xrdp-sesman &\n\
# xrdp -n &\n\
\n\
# Keep container running\n\
echo "=========================================="\n\
echo "VNC Desktop is ready!"\n\
echo "Connect via:"\n\
echo "• Web: https://$RENDER_EXTERNAL_HOSTNAME/vnc.html"\n\
echo "• Password: $VNC_PASSWORD"\n\
echo "=========================================="\n\
\n\
# Tail logs to keep container alive\n\
tail -f /dev/null' > /start.sh && chmod +x /start.sh

# Alternative: Simple start script for Render
RUN echo '#!/bin/bash\n\
# Set VNC password\n\
mkdir -p /root/.vnc\n\
echo "$VNC_PASSWORD" | vncpasswd -f > /root/.vnc/passwd\n\
chmod 600 /root/.vnc/passwd\n\
\n\
# Set up XFCE autostart\n\
mkdir -p /root/.config/autostart\n\
echo "[Desktop Entry]\n\
Type=Application\n\
Exec=xfce4-terminal\n\
Hidden=false\n\
NoDisplay=false\n\
X-GNOME-Autostart-enabled=true\n\
Name[en_US]=Terminal\n\
Name=Terminal\n\
Comment[en_US]=Start Terminal\n\
Comment=Start Terminal" > /root/.config/autostart/terminal.desktop\n\
\n\
# Start VNC server\n\
vncserver :1 -geometry $VNC_RESOLUTION -depth $VNC_DEPTH -localhost no -SecurityTypes VncAuth -xstartup /root/.vnc/xstartup\n\
\n\
# Start noVNC\n\
/opt/novnc/utils/novnc_proxy --vnc localhost:5901 --listen 0.0.0.0:8080\n\
' > /start-vnc.sh && chmod +x /start-vnc.sh

# Create a one-command startup script for Render
RUN echo '#!/bin/bash\n\
\n\
# Default values\n\
VNC_PASSWORD=${VNC_PASSWORD:-"password"}\n\
VNC_RESOLUTION=${VNC_RESOLUTION:-"1280x720"}\n\
VNC_DEPTH=${VNC_DEPTH:-"24"}\n\
\n\
echo "Starting lightweight VNC desktop..."\n\
echo "Resolution: $VNC_RESOLUTION"\n\
echo "Password: $VNC_PASSWORD"\n\
\n\
# Setup VNC\n\
mkdir -p /root/.vnc\n\
echo "$VNC_PASSWORD" | vncpasswd -f > /root/.vnc/passwd\n\
chmod 600 /root/.vnc/passwd\n\
\n\
# Create xstartup for XFCE\n\
cat > /root/.vnc/xstartup << "EOF"\n\
#!/bin/bash\n\
unset SESSION_MANAGER\n\
unset DBUS_SESSION_BUS_ADDRESS\n\
exec startxfce4\n\
EOF\n\
chmod +x /root/.vnc/xstartup\n\
\n\
# Kill existing session\n\
vncserver -kill :1 2>/dev/null || true\n\
rm -rf /tmp/.X11-unix/X1 /tmp/.X1-lock /root/.vnc/*.log /root/.vnc/*.pid\n\
\n\
# Start VNC server\n\
vncserver :1 \\\n\
    -geometry $VNC_RESOLUTION \\\n\
    -depth $VNC_DEPTH \\\n\
    -localhost no \\\n\
    -SecurityTypes VncAuth \\\n\
    -AlwaysShared \\\n\
    -AcceptKeyEvents \\\n\
    -AcceptPointerEvents \\\n\
    -AcceptSetDesktopSize \\\n\
    -SendCutText \\\n\
    -ReceiveCutText \\\n\
    -xstartup /root/.vnc/xstartup\n\
\n\
# Start noVNC\n\
echo "Starting noVNC on port 8080..."\n\
/opt/novnc/utils/novnc_proxy --vnc localhost:5901 --listen 0.0.0.0:8080 \\\n\
    --heartbeat 30 \\\n\
    --web /opt/novnc\n\
\n\
echo "=========================================="\n\
echo "     VNC Desktop is ready!"\n\
echo "=========================================="\n\
echo "Connect via web browser:"\n\
echo "• URL: https://$RENDER_EXTERNAL_HOSTNAME"\n\
echo "• Password: $VNC_PASSWORD"\n\
echo "=========================================="\n\
\n\
# Keep the container running\n\
tail -f /dev/null\n\
' > /start-render.sh && chmod +x /start-render.sh

# Expose ports
EXPOSE 8080 5901

# Health check (for Render)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/ || exit 1

# Start the service
CMD ["/bin/bash", "/start-render.sh"]
