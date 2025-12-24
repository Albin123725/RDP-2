# 🚀 Direct Web RDP Browser - Simplified
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install ALL dependencies
RUN apt-get update && apt-get install -y \
    # X server
    xvfb \
    xserver-xorg-video-dummy \
    # VNC
    x11vnc \
    # Window manager
    openbox \
    # Browser
    wget \
    gnupg \
    ca-certificates \
    # Web server
    python3 \
    python3-pip \
    # Fonts
    fonts-liberation \
    # Utilities
    curl \
    net-tools \
    # Clean
    && rm -rf /var/lib/apt/lists/*

# Install Chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Install Flask + websockify
RUN pip3 install flask websockify

# Create user
RUN useradd -m -u 1000 -s /bin/bash user

# Create app.py directly in Dockerfile
RUN echo '#!/usr/bin/env python3' > /app.py && \
echo '"""' >> /app.py && \
echo '🚀 Direct Web RDP Interface' >> /app.py && \
echo '"""' >> /app.py && \
echo '' >> /app.py && \
echo 'from flask import Flask, render_template_string, jsonify' >> /app.py && \
echo 'import os' >> /app.py && \
echo 'import time' >> /app.py && \
echo '' >> /app.py && \
echo 'app = Flask(__name__)' >> /app.py && \
echo '' >> /app.py && \
echo '# Get Render external URL' >> /app.py && \
echo 'RENDER_EXTERNAL_URL = os.environ.get("RENDER_EXTERNAL_URL", "http://localhost:10000")' >> /app.py && \
echo '' >> /app.py && \
echo 'HTML = """<!DOCTYPE html>' >> /app.py && \
echo '<html>' >> /app.py && \
echo '<head>' >> /app.py && \
echo '    <meta charset="UTF-8">' >> /app.py && \
echo '    <meta name="viewport" content="width=device-width, initial-scale=1.0">' >> /app.py && \
echo '    <title>🚀 Direct RDP Browser</title>' >> /app.py && \
echo '    <style>' >> /app.py && \
echo '        :root {' >> /app.py && \
echo '            --primary: #3b82f6;' >> /app.py && \
echo '            --success: #10b981;' >> /app.py && \
echo '            --bg-dark: #0f172a;' >> /app.py && \
echo '        }' >> /app.py && \
echo '        ' >> /app.py && \
echo '        * { margin: 0; padding: 0; box-sizing: border-box; }' >> /app.py && \
echo '        ' >> /app.py && \
echo '        body {' >> /app.py && \
echo '            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;' >> /app.py && \
echo '            background: linear-gradient(135deg, var(--bg-dark) 0%, #1e293b 100%);' >> /app.py && \
echo '            color: white;' >> /app.py && \
echo '            min-height: 100vh;' >> /app.py && \
echo '            padding: 20px;' >> /app.py && \
echo '        }' >> /app.py && \
echo '        ' >> /app.py && \
echo '        .container {' >> /app.py && \
echo '            max-width: 1200px;' >> /app.py && \
echo '            margin: 0 auto;' >> /app.py && \
echo '            background: rgba(255, 255, 255, 0.05);' >> /app.py && \
echo '            border-radius: 20px;' >> /app.py && \
echo '            padding: 30px;' >> /app.py && \
echo '            border: 1px solid rgba(255, 255, 255, 0.1);' >> /app.py && \
echo '        }' >> /app.py && \
echo '        ' >> /app.py && \
echo '        h1 {' >> /app.py && \
echo '            text-align: center;' >> /app.py && \
echo '            margin-bottom: 10px;' >> /app.py && \
echo '            background: linear-gradient(135deg, #60a5fa 0%, #3b82f6 100%);' >> /app.py && \
echo '            -webkit-background-clip: text;' >> /app.py && \
echo '            -webkit-text-fill-color: transparent;' >> /app.py && \
echo '            font-size: 2.5em;' >> /app.py && \
echo '        }' >> /app.py && \
echo '        ' >> /app.py && \
echo '        .vnc-container {' >> /app.py && \
echo '            width: 100%;' >> /app.py && \
echo '            height: 600px;' >> /app.py && \
echo '            border: 2px solid rgba(255, 255, 255, 0.1);' >> /app.py && \
echo '            border-radius: 10px;' >> /app.py && \
echo '            overflow: hidden;' >> /app.py && \
echo '            margin: 20px 0;' >> /app.py && \
echo '            background: black;' >> /app.py && \
echo '        }' >> /app.py && \
echo '        ' >> /app.py && \
echo '        .btn {' >> /app.py && \
echo '            padding: 12px 24px;' >> /app.py && \
echo '            background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%);' >> /app.py && \
echo '            color: white;' >> /app.py && \
echo '            border: none;' >> /app.py && \
echo '            border-radius: 8px;' >> /app.py && \
echo '            cursor: pointer;' >> /app.py && \
echo '            font-weight: 600;' >> /app.py && \
echo '            margin: 10px;' >> /app.py && \
echo '        }' >> /app.py && \
echo '        ' >> /app.py && \
echo '        .btn:hover {' >> /app.py && \
echo '            transform: translateY(-2px);' >> /app.py && \
echo '            box-shadow: 0 5px 15px rgba(37, 99, 235, 0.4);' >> /app.py && \
echo '        }' >> /app.py && \
echo '    </style>' >> /app.py && \
echo '</head>' >> /app.py && \
echo '<body>' >> /app.py && \
echo '    <div class="container">' >> /app.py && \
echo '        <h1>🚀 Direct RDP Browser</h1>' >> /app.py && \
echo '        <p style="text-align: center; color: #94a3b8; margin-bottom: 30px;">' >> /app.py && \
echo '            Access Chrome browser directly via this page' >> /app.py && \
echo '        </p>' >> /app.py && \
echo '        ' >> /app.py && \
echo '        <div class="vnc-container" id="vncContainer">' >> /app.py && \
echo '            <div style="padding: 40px; text-align: center; color: white;">' >> /app.py && \
echo '                <h2>Loading RDP Browser...</h2>' >> /app.py && \
echo '                <p>Click "Connect" button below to start</p>' >> /app.py && \
echo '            </div>' >> /app.py && \
echo '        </div>' >> /app.py && \
echo '        ' >> /app.py && \
echo '        <div style="text-align: center; margin: 20px 0;">' >> /app.py && \
echo '            <button class="btn" onclick="connectVNC()">' >> /app.py && \
echo '                🔗 Connect to Browser' >> /app.py && \
echo '            </button>' >> /app.py && \
echo '            <button class="btn" onclick="location.reload()" style="background: linear-gradient(135deg, #10b981 0%, #059669 100%);">' >> /app.py && \
echo '                🔄 Refresh' >> /app.py && \
echo '            </button>' >> /app.py && \
echo '        </div>' >> /app.py && \
echo '    </div>' >> /app.py && \
echo '    ' >> /app.py && \
echo '    <script src="https://cdn.jsdelivr.net/npm/@novnc/novnc@1.4.0/lib/rfb.min.js"></script>' >> /app.py && \
echo '    <script>' >> /app.py && \
echo '        let rfb;' >> /app.py && \
echo '        ' >> /app.py && \
echo '        function connectVNC() {' >> /app.py && \
echo '            // Hide any existing connection' >> /app.py && \
echo '            if (rfb) {' >> /app.py && \
echo '                rfb.disconnect();' >> /app.py && \
echo '            }' >> /app.py && \
echo '            ' >> /app.py && \
echo '            // Create WebSocket URL' >> /app.py && \
echo '            const protocol = window.location.protocol === "https:" ? "wss:" : "ws:";' >> /app.py && \
echo '            const host = window.location.host;' >> /app.py && \
echo '            const wsUrl = protocol + "//" + host + "/websockify";' >> /app.py && \
echo '            ' >> /app.py && \
echo '            console.log("Connecting to:", wsUrl);' >> /app.py && \
echo '            ' >> /app.py && \
echo '            // Connect to noVNC' >> /app.py && \
echo '            rfb = new RFB(document.getElementById("vncContainer"), wsUrl, {' >> /app.py && \
echo '                shared: true,' >> /app.py && \
echo '                credentials: { password: "" },' >> /app.py && \
echo '                wsProtocols: ["binary"]' >> /app.py && \
echo '            });' >> /app.py && \
echo '            ' >> /app.py && \
echo '            rfb.addEventListener("connect", () => {' >> /app.py && \
echo '                console.log("✅ Connected to RDP session");' >> /app.py && \
echo '            });' >> /app.py && \
echo '        }' >> /app.py && \
echo '        ' >> /app.py && \
echo '        // Auto-connect after 2 seconds' >> /app.py && \
echo '        setTimeout(connectVNC, 2000);' >> /app.py && \
echo '    </script>' >> /app.py && \
echo '</body>' >> /app.py && \
echo '</html>"""' >> /app.py && \
echo '' >> /app.py && \
echo '@app.route("/")' >> /app.py && \
echo 'def index():' >> /app.py && \
echo '    return render_template_string(HTML)' >> /app.py && \
echo '' >> /app.py && \
echo '@app.route("/vnc.html")' >> /app.py && \
echo 'def vnc_html():' >> /app.py && \
echo '    return """<!DOCTYPE html>' >> /app.py && \
echo '<html>' >> /app.py && \
echo '<head>' >> /app.py && \
echo '    <title>🚀 RDP Browser - Full Screen</title>' >> /app.py && \
echo '    <meta charset="UTF-8">' >> /app.py && \
echo '    <style>body, html { margin: 0; padding: 0; height: 100%; overflow: hidden; }</style>' >> /app.py && \
echo '    <script src="https://cdn.jsdelivr.net/npm/@novnc/novnc@1.4.0/lib/rfb.min.js"></script>' >> /app.py && \
echo '</head>' >> /app.py && \
echo '<body>' >> /app.py && \
echo '    <div id="noVNC_container" style="width: 100vw; height: 100vh;"></div>' >> /app.py && \
echo '    <script>' >> /app.py && \
echo '        const protocol = window.location.protocol === "https:" ? "wss:" : "ws:";' >> /app.py && \
echo '        const host = window.location.host;' >> /app.py && \
echo '        const wsUrl = protocol + "//" + host + "/websockify";' >> /app.py && \
echo '        ' >> /app.py && \
echo '        const rfb = new RFB(document.getElementById("noVNC_container"), wsUrl, {' >> /app.py && \
echo '            shared: true,' >> /app.py && \
echo '            credentials: { password: "" }' >> /app.py && \
echo '        });' >> /app.py && \
echo '    </script>' >> /app.py && \
echo '</body>' >> /app.py && \
echo '</html>"""' >> /app.py && \
echo '' >> /app.py && \
echo '@app.route("/health")' >> /app.py && \
echo 'def health():' >> /app.py && \
echo '    return jsonify({"status": "healthy", "timestamp": time.time()}), 200' >> /app.py && \
echo '' >> /app.py && \
echo '@app.route("/status")' >> /app.py && \
echo 'def status():' >> /app.py && \
echo '    return jsonify({"status": "running", "service": "direct-rdp-browser"})' >> /app.py && \
echo '' >> /app.py && \
echo 'if __name__ == "__main__":' >> /app.py && \
echo '    port = int(os.environ.get("PORT", 10000))' >> /app.py && \
echo '    app.run(host="0.0.0.0", port=port, debug=False)' >> /app.py

# Create startup script
RUN echo '#!/bin/bash' > /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start Xvfb' >> /start.sh && \
    echo 'Xvfb :99 -screen 0 1280x1024x24 -ac +extension RANDR -nolisten tcp &' >> /start.sh && \
    echo 'sleep 3' >> /start.sh && \
    echo '' >> /start.sh && \
    echo 'export DISPLAY=:99' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start Openbox' >> /start.sh && \
    echo 'openbox &' >> /start.sh && \
    echo 'sleep 2' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start Chrome' >> /start.sh && \
    echo 'google-chrome-stable --no-sandbox --disable-dev-shm-usage --start-maximized &' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start VNC server' >> /start.sh && \
    echo 'x11vnc -display :99 -forever -shared -nopw -listen 127.0.0.1 -rfbport 5900 -noxdamage &' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start websockify proxy' >> /start.sh && \
    echo 'websockify --web /usr/share/novnc 6080 localhost:5900 &' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Start Flask web server' >> /start.sh && \
    echo 'python3 /app.py &' >> /start.sh && \
    echo '' >> /start.sh && \
    echo 'echo "✅ RDP Browser Ready!"' >> /start.sh && \
    echo 'echo "🌐 Connect directly to your Render URL"' >> /start.sh && \
    echo '' >> /start.sh && \
    echo '# Keep container running' >> /start.sh && \
    echo 'tail -f /dev/null' >> /start.sh && \
    chmod +x /start.sh

USER user
EXPOSE 10000
CMD ["/start.sh"]
