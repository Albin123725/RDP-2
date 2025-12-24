# 🚀 Ultra-Minimal RDP Browser - Fixed for Render
# Uses virtual environment to avoid PEP 668 restrictions

FROM alpine:edge

# Install ALL packages in one RUN to minimize layers
RUN apk add --no-cache --update \
    # Browser runtime
    chromium \
    chromium-chromedriver \
    # X11 display
    xvfb \
    x11vnc \
    # Minimal window manager
    fluxbox \
    # Web VNC
    novnc \
    websockify \
    # Python with virtual environment
    python3 \
    py3-pip \
    py3-virtualenv \
    # Required system libraries
    dbus \
    ttf-freefont \
    ttf-dejavu \
    # Cleanup
    && rm -rf /var/cache/apk/*

# Create virtual environment BEFORE installing packages
RUN python3 -m venv /app/venv

# Install Python packages in virtual environment
RUN /app/venv/bin/pip install --no-cache-dir \
    flask==2.3.3 \
    gunicorn==21.2.0 \
    psutil==5.9.5

# Create non-root user
RUN adduser -D -u 1000 browseruser \
    && mkdir -p /home/browseruser/.config \
    && chown -R browseruser:browseruser /home/browseruser

# Create app directory
WORKDIR /app

# Copy application files
COPY rdp-browser.py /app/
COPY requirements.txt /app/

# Set environment variables
ENV DISPLAY=:99
ENV CHROMIUM_FLAGS="--no-sandbox --disable-dev-shm-usage --disable-gpu --disable-software-rasterizer"
ENV HOME=/tmp
ENV PORT=10000
ENV PATH="/app/venv/bin:$PATH"

# Create optimized startup script
RUN echo '#!/bin/sh' > /app/start.sh && \
    echo 'set -e' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Export virtual environment path' >> /app/start.sh && \
    echo 'export PATH="/app/venv/bin:$PATH"' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start Xvfb' >> /app/start.sh && \
    echo 'Xvfb :99 -screen 0 1024x768x16 -ac +extension GLX +render -noreset >/dev/null 2>&1 &' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Wait for X server' >> /app/start.sh && \
    echo 'sleep 2' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start fluxbox' >> /app/start.sh && \
    echo 'fluxbox >/dev/null 2>&1 &' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start browser' >> /app/start.sh && \
    echo 'chromium-browser $CHROMIUM_FLAGS --start-maximized --app="https://literate-cod-g474wqj4x9f59p.github.dev/?editor=jupyter" >/dev/null 2>&1 &' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start VNC server (no password)' >> /app/start.sh && \
    echo 'x11vnc -display :99 -forever -shared -nopw -listen 0.0.0.0 -rfbport 5901 -noxdamage >/dev/null 2>&1 &' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start noVNC web interface' >> /app/start.sh && \
    echo 'websockify --web /usr/share/novnc 6081 localhost:5901 >/dev/null 2>&1 &' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start Flask control panel' >> /app/start.sh && \
    echo 'cd /app && python3 rdp-browser.py >/dev/null 2>&1 &' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Keep container running' >> /app/start.sh && \
    echo 'tail -f /dev/null' >> /app/start.sh && \
    chmod +x /app/start.sh

# Set permissions
RUN chown -R browseruser:browseruser /app

# Switch to non-root user
USER browseruser

# Expose ports
EXPOSE 10000 5901 6081

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:10000/health || exit 1

# Start everything
CMD ["/bin/sh", "/app/start.sh"]
