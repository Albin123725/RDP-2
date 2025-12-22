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
RUN echo '<!DOCTYPE html>
<html>
<head>
    <title>VNC Desktop</title>
    <meta charset="utf-8">
    <style>
        body {
            font-family: Arial, sans-serif;
            text-align: center;
            padding: 50px;
            background: #f0f0f0;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
            max-width: 600px;
            margin: 0 auto;
        }
        .button {
            display: inline-block;
            padding: 15px 30px;
            background: #4CAF50;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            font-size: 18px;
            margin: 20px 0;
        }
        .button:hover {
            background: #45a049;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Remote Desktop</h1>
        <p>Click the button below to access your desktop:</p>
        <a href="/vnc.html" class="button">Launch Desktop</a>
        <p>Or go directly to: <a href="/vnc.html">/vnc.html</a></p>
        <p>Username/password not required. Just click "Connect".</p>
    </div>
</body>
</html>' > /var/www/html/index.html

# Configure nginx to serve noVNC and redirect root to vnc.html
RUN echo 'server {
    listen 8080;
    root /usr/share/novnc;
    
    location / {
        try_files $uri $uri/ /vnc.html;
    }
    
    location /websockify {
        proxy_pass http://localhost:6080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
}' > /etc/nginx/sites-available/default

# Alternative: Simple Python HTTP server config
RUN echo 'server {
    listen 8080;
    server_name _;
    
    location / {
        root /usr/share/novnc;
        index vnc.html;
        try_files $uri $uri/ =404;
    }
}' > /etc/nginx/novnc.conf

# Create startup script
RUN cat > /start.sh << 'EOF'
#!/bin/bash

echo "=== Starting Remote Desktop Service ==="

# Get Render's port
PORT=${PORT:-10000}
echo "Service will run on port: $PORT"

# Start Xvfb (virtual display)
echo "Starting virtual display..."
Xvfb :99 -screen 0 1024x768x24 -ac +extension GLX &
sleep 2

# Set display
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

# Start noVNC with websockify on port 6080
echo "Starting WebSocket proxy..."
websockify --web /usr/share/novnc 6080 localhost:5900 &
sleep 2

# Start nginx to serve HTTP on Render's port
echo "Starting HTTP server on port $PORT..."
nginx -g 'daemon off;' &
sleep 2

# Also run a simple Python HTTP server as backup
echo "Starting backup HTTP server..."
cd /usr/share/novnc && python3 -m http.server $PORT --bind 0.0.0.0 &

echo "=== Service started successfully ==="
echo "Access your desktop at: http://your-app.onrender.com/vnc.html"

# Keep container running
tail -f /dev/null
EOF

RUN chmod +x /start.sh

# Health check endpoint
RUN echo '#!/bin/bash
# Simple health check
curl -f http://localhost:${PORT:-10000}/ || exit 1' > /healthcheck.sh
RUN chmod +x /healthcheck.sh

EXPOSE 10000

CMD ["/bin/bash", "/start.sh"]
