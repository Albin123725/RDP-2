FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:99

# Install minimal packages
RUN apt-get update && apt-get install -y \
    xvfb \
    fluxbox \
    x11vnc \
    novnc \
    xterm \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create startup script - properly escaped
RUN echo '#!/bin/bash\n\
echo "Starting desktop..."\n\
\n\
# Start virtual display\n\
Xvfb :99 -screen 0 800x600x16 &\n\
sleep 2\n\
\n\
# Start window manager\n\
fluxbox &\n\
sleep 2\n\
\n\
# Start VNC server\n\
x11vnc -display :99 -forever -shared -nopw -listen 0.0.0.0 -rfbport 5900 &\n\
sleep 2\n\
\n\
# Start noVNC on Render port\n\
/usr/share/novnc/utils/novnc_proxy --vnc localhost:5900 --listen 0.0.0.0:${PORT:-10000}\n\
\n\
# Keep running\n\
tail -f /dev/null' > /start.sh && chmod +x /start.sh

EXPOSE 10000

CMD ["/bin/bash", "/start.sh"]
