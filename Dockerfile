# 🚀 Ultra-Minimal RDP Browser
# Only browser, no desktop, ~150MB memory

# Stage 1: Build minimal base
FROM alpine:edge AS builder

# Install ONLY essential packages for browser
RUN apk add --no-cache --update \
    # Browser runtime
    chromium \
    chromium-chromedriver \
    # Minimal X11 for display
    xvfb \
    x11vnc \
    # Window manager (lightest available)
    fluxbox \
    # Web VNC interface
    novnc \
    websockify \
    # Required system libraries
    dbus \
    ttf-freefont \
    ttf-dejavu \
    # Python for control panel
    python3 \
    py3-pip \
    # Cleanup
    && rm -rf /var/cache/apk/*

# Stage 2: Final image
FROM alpine:edge

# Copy from builder
COPY --from=builder / /

# Install Python dependencies ONLY
RUN apk add --no-cache \
    python3 \
    py3-pip \
    && pip3 install --no-cache-dir \
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

# Create startup script
RUN echo '#!/bin/sh' > /app/start.sh && \
    echo 'set -e' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start Xvfb in background' >> /app/start.sh && \
    echo 'Xvfb :99 -screen 0 1024x768x16 &' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Wait for X server' >> /app/start.sh && \
    echo 'sleep 2' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start fluxbox (minimal window manager)' >> /app/start.sh && \
    echo 'fluxbox &' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start browser with target URL' >> /app/start.sh && \
    echo 'chromium-browser $CHROMIUM_FLAGS --start-maximized --app="https://literate-cod-g474wqj4x9f59p.github.dev/?editor=jupyter" &' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start x11vnc (no password)' >> /app/start.sh && \
    echo 'x11vnc -display :99 -forever -shared -nopw -listen 0.0.0.0 -rfbport 5901 &' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start noVNC web interface' >> /app/start.sh && \
    echo 'websockify --web /usr/share/novnc 6081 localhost:5901 &' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Start Flask control panel' >> /app/start.sh && \
    echo 'cd /app && python3 rdp-browser.py &' >> /app/start.sh && \
    echo '' >> /app/start.sh && \
    echo '# Keep container running' >> /app/start.sh && \
    echo 'wait' >> /app/start.sh && \
    chmod +x /app/start.sh

# Set permissions
RUN chown -R browseruser:browseruser /app

# Switch to non-root user
USER browseruser

# Expose ports
# 10000: Control panel
# 5901: VNC
# 6081: Web VNC
EXPOSE 10000 5901 6081

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:10000/health || exit 1

# Start everything
CMD ["/bin/sh", "/app/start.sh"]
