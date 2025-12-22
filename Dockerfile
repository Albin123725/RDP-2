FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install packages including a web server
RUN apt-get update && apt-get install -y \
    xvfb \
    fluxbox \
    x11vnc \
    novnc \
    xterm \
    python3 \
    python3-websockify \
    nginx \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create a simple HTML page for the root URL
RUN mkdir -p /var/www/html
RUN echo '<!DOCTYPE html>' > /var/www/html/index.html && \
    echo '<html>' >> /var/www/html/index.html && \
    echo '<head>' >> /var/www/html/index.html && \
    echo '    <title>VNC Desktop</title>' >> /var/www/html/index.html && \
    echo '    <meta charset="utf-8">' >> /var/www/html/index.html && \
    echo '    <style>' >> /var/www/html/index.html && \
    echo '        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; background: #f0f0f0; }' >> /var/www/html/index.html && \
    echo '        .container { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 0 10px rgba(0,0,0,0.1); max-width: 600px; margin: 0 auto; }' >> /var/www/html/index.html && \
    echo '        .button { display: inline-block; padding: 15px 30px; background: #4CAF50; color: white; text-decoration: none; border-radius: 5px; font-size: 18px; margin: 20px 0; }' >> /var/www/html/index.html && \
    echo '        .button:hover { background: #45a049; }' >> /var/www/html/index.html && \
    echo '    </style>' >> /var/www/html/index.html && \
    echo '</head>' >> /var/www/html/index.html && \
    echo '<body>' >> /var/www/html/index.html && \
    echo '    <div class="container">' >> /var/www/html/index.html && \
    echo '        <h1>Remote Desktop</h1>' >> /var/www/html/index.html && \
    echo '        <p>Click the button below to access your desktop:</p>' >> /var/www/html/index.html && \
    echo '        <a href="/vnc.html" class="button">Launch Desktop</a>' >> /var/www/html/index.html && \
    echo '        <p>Or go directly to: <a href="/vnc.html">/vnc.html</a></p>' >> /var/www/html/index.html && \
    echo '        <p>Username/password not required. Just click "Connect".</p>' >> /var/www/html/index.html && \
    echo '    </div>' >> /var/www/html/index.html && \
    echo '</body>' >> /var/www/html/index.html && \
    echo '</html>' >> /var/www/html/index.html

# Configure nginx
RUN echo 'server {' > /etc/nginx/sites-available/default && \
    echo '    listen 8080;' >> /etc/nginx/sites-available/default && \
    echo '    root /usr/share/novnc;' >> /etc/nginx/sites-available/default && \
    echo '    location / {' >> /etc/nginx/sites-available/default && \
    echo '        try_files $uri $uri/ /vnc.html;' >> /etc/nginx/sites-available/default && \
    echo '    }' >> /etc/nginx/sites-available/default && \
    echo '}' >> /etc/nginx/sites-available/default

# Create startup script using cat (heredoc)
RUN cat > /start.sh << 'EOF'
#!/bin/bash

echo "=== Starting Remote Desktop Service ==="

# Get Render's port
PORT=${PORT:-10000}
echo "Service will run on port: $PORT"

# Start Xvfb
echo "Starting virtual display..."
Xvfb :99 -screen 0 1024x768x24 -ac &
sleep 2

export DISPLAY=:99

# Start window manager
echo "Starting window manager..."
fluxbox &
sleep 2

# Start a terminal
echo "Starting terminal..."
xterm -geometry 80x24+10+10 -e "echo Desktop is ready!" &
sleep 1

# Start VNC server
echo "Starting VNC server..."
x11vnc -display :99 -forever -shared -nopw -listen 0.0.0.0 -rfbport 5900 &
sleep 2

# Start websockify
echo "Starting WebSocket proxy..."
websockify --web /usr/share/novnc $PORT localhost:5900

echo "=== Service started successfully ==="
EOF

RUN chmod +x /start.sh

EXPOSE 10000

CMD ["/bin/bash", "/start.sh"]
