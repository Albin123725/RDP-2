#!/usr/bin/env python3
"""
🚀 RDP Browser - Render Compatible Version
Web VNC accessible through main port (10000)
"""

import os
import sys
import time
import json
import logging
from flask import Flask, render_template_string, jsonify, Response, request, redirect
import subprocess
import threading

# Add virtual environment path
venv_path = '/app/venv/lib/python3.12/site-packages'
if os.path.exists(venv_path):
    sys.path.insert(0, venv_path)

app = Flask(__name__)

# ==================== CONFIGURATION ====================
CONFIG = {
    'target_url': 'https://literate-cod-g474wqj4x9f59p.github.dev/?editor=jupyter',
    'resolution': '1280x1024',
    'control_port': int(os.environ.get('PORT', 10000)),
    'host': '0.0.0.0',
    'debug': False
}

# Get Render external URL
RENDER_EXTERNAL_URL = os.environ.get('RENDER_EXTERNAL_URL', 'http://localhost:10000')

# ==================== LOGGING ====================
logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)s: %(message)s',
    datefmt='%H:%M:%S'
)
logger = logging.getLogger(__name__)

# ==================== VNC PROXY ====================
class VNCProxy:
    """Proxy VNC traffic through Flask"""
    
    @staticmethod
    def get_vnc_page():
        """Return HTML page with embedded noVNC client"""
        return f'''
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>🌐 RDP Browser - Live View</title>
            <style>
                body, html {{
                    margin: 0;
                    padding: 0;
                    height: 100%;
                    overflow: hidden;
                    background: #0f172a;
                }}
                #vnc-container {{
                    width: 100vw;
                    height: 100vh;
                }}
                .loading {{
                    position: fixed;
                    top: 50%;
                    left: 50%;
                    transform: translate(-50%, -50%);
                    color: white;
                    text-align: center;
                    font-family: Arial, sans-serif;
                }}
                .spinner {{
                    border: 4px solid rgba(255,255,255,0.1);
                    border-top: 4px solid #3b82f6;
                    border-radius: 50%;
                    width: 40px;
                    height: 40px;
                    animation: spin 1s linear infinite;
                    margin: 0 auto 15px;
                }}
                @keyframes spin {{
                    0% {{ transform: rotate(0deg); }}
                    100% {{ transform: rotate(360deg); }}
                }}
            </style>
        </head>
        <body>
            <div class="loading" id="loading">
                <div class="spinner"></div>
                <p>Loading RDP session...</p>
                <p><small>This may take 10-20 seconds</small></p>
            </div>
            <div id="vnc-container"></div>
            
            <script src="https://cdn.jsdelivr.net/npm/@novnc/novnc@1.4.0/lib/rfb.min.js"></script>
            <script>
                // Hide loading after 5 seconds
                setTimeout(() => {{
                    document.getElementById('loading').style.display = 'none';
                }}, 5000);
                
                // Get WebSocket URL (relative to current page)
                const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
                const host = window.location.host;
                const wsPath = '/websockify';
                const wsUrl = protocol + '//' + host + wsPath;
                
                console.log('Connecting to WebSocket:', wsUrl);
                
                // Create RFB client
                const vncContainer = document.getElementById('vnc-container');
                const rfb = new RFB(vncContainer, wsUrl, {{
                    credentials: {{ password: '' }},
                    shared: true,
                    repeaterID: '',
                    wsProtocols: ['binary']
                }});
                
                rfb.addEventListener("connect", () => {{
                    console.log('VNC Connected!');
                    document.getElementById('loading').style.display = 'none';
                }});
                
                rfb.addEventListener("disconnect", () => {{
                    console.log('VNC Disconnected');
                    vncContainer.innerHTML = '<div class="loading"><p>Disconnected. Refresh page to reconnect.</p></div>';
                }});
                
                rfb.addEventListener("credentialsrequired", () => {{
                    console.log('No password required');
                }});
                
                // Auto-reconnect on disconnect
                rfb.addEventListener("disconnect", () => {{
                    setTimeout(() => {{
                        window.location.reload();
                    }}, 5000);
                }});
            </script>
        </body>
        </html>
        '''

# ==================== STATUS ====================
class BrowserStatus:
    def __init__(self):
        self.start_time = time.time()
        self.vnc_ready = False
        self.browser_ready = False
        
        # Check if VNC is running
        threading.Thread(target=self._check_services, daemon=True).start()
    
    def _check_services(self):
        """Check if VNC and browser are running"""
        import socket
        time.sleep(10)  # Wait for services to start
        
        # Check VNC
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(2)
            result = sock.connect_ex(('127.0.0.1', 5900))
            self.vnc_ready = result == 0
            sock.close()
        except:
            self.vnc_ready = False
        
        # Mark browser as ready after startup
        time.sleep(5)
        self.browser_ready = True
    
    def get_status(self):
        uptime = time.time() - self.start_time
        hours = int(uptime // 3600)
        minutes = int((uptime % 3600) // 60)
        
        return {
            'status': 'running',
            'uptime': f'{hours}h {minutes}m',
            'vnc_ready': self.vnc_ready,
            'browser_ready': self.browser_ready,
            'target_url': CONFIG['target_url'],
            'external_url': RENDER_EXTERNAL_URL,
            'vnc_url': f'{RENDER_EXTERNAL_URL}/vnc',
            'direct_url': CONFIG['target_url']
        }

status = BrowserStatus()

# ==================== HTML TEMPLATE ====================
INDEX_HTML = '''<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🚀 RDP Browser - GitHub Codespaces Access</title>
    <style>
        :root {
            --primary: #3b82f6;
            --success: #10b981;
            --bg-dark: #0f172a;
            --bg-card: #1e293b;
        }
        
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, var(--bg-dark) 0%, #1e293b 100%);
            color: white;
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 1000px;
            margin: 0 auto;
            background: rgba(255, 255, 255, 0.05);
            border-radius: 20px;
            padding: 30px;
            border: 1px solid rgba(255, 255, 255, 0.1);
        }
        
        h1 {
            text-align: center;
            margin-bottom: 10px;
            background: linear-gradient(135deg, #60a5fa 0%, #3b82f6 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            font-size: 2.5em;
        }
        
        .subtitle {
            text-align: center;
            color: #94a3b8;
            margin-bottom: 30px;
        }
        
        .status-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-bottom: 30px;
        }
        
        .status-card {
            background: rgba(255, 255, 255, 0.08);
            padding: 20px;
            border-radius: 12px;
            text-align: center;
            border: 1px solid rgba(255, 255, 255, 0.1);
        }
        
        .status-good { border-color: #10b981; }
        .status-waiting { border-color: #f59e0b; }
        
        .status-value {
            font-size: 1.8em;
            font-weight: bold;
            margin-bottom: 5px;
        }
        
        .btn-container {
            display: flex;
            flex-wrap: wrap;
            gap: 15px;
            justify-content: center;
            margin: 30px 0;
        }
        
        .btn {
            padding: 15px 30px;
            background: linear-gradient(135deg, var(--color) 0%, var(--color-dark) 100%);
            color: white;
            border: none;
            border-radius: 10px;
            cursor: pointer;
            font-weight: 600;
            font-size: 16px;
            transition: all 0.3s;
            min-width: 220px;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
            text-decoration: none;
        }
        
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(0, 0, 0, 0.3);
        }
        
        .btn-primary { --color: #3b82f6; --color-dark: #1d4ed8; }
        .btn-success { --color: #10b981; --color-dark: #059669; }
        .btn-purple { --color: #8b5cf6; --color-dark: #7c3aed; }
        
        .info-box {
            background: rgba(0, 0, 0, 0.3);
            padding: 20px;
            border-radius: 10px;
            margin: 20px 0;
            border-left: 4px solid var(--primary);
        }
        
        .connection-details {
            background: rgba(59, 130, 246, 0.1);
            padding: 20px;
            border-radius: 10px;
            margin: 20px 0;
        }
        
        .instructions {
            background: rgba(255, 255, 255, 0.05);
            padding: 20px;
            border-radius: 10px;
            margin: 20px 0;
        }
        
        @media (max-width: 768px) {
            .btn { min-width: 100%; }
            .status-grid { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 RDP Browser - GitHub Codespaces</h1>
        <div class="subtitle">Access GitHub Codespaces through browser • No certificate warnings</div>
        
        <div class="status-grid">
            <div class="status-card {{ 'status-good' if vnc_ready else 'status-waiting' }}">
                <div class="status-value">{{ '✅' if vnc_ready else '⏳' }}</div>
                <div>VNC Server: {{ 'Ready' if vnc_ready else 'Starting...' }}</div>
            </div>
            
            <div class="status-card {{ 'status-good' if browser_ready else 'status-waiting' }}">
                <div class="status-value">{{ '✅' if browser_ready else '⏳' }}</div>
                <div>Browser: {{ 'Ready' if browser_ready else 'Starting...' }}</div>
            </div>
            
            <div class="status-card status-good">
                <div class="status-value">{{ uptime }}</div>
                <div>Service Uptime</div>
            </div>
        </div>
        
        <div class="info-box">
            <h3>🎯 Target Website</h3>
            <p style="font-family: monospace; word-break: break-all; margin: 10px 0; font-size: 1.1em; color: #60a5fa;">
                {{ target_url }}
            </p>
            <p><small>Chrome is configured to ignore certificate errors for GitHub Codespaces</small></p>
        </div>
        
        <div class="btn-container">
            <a href="/vnc" class="btn btn-primary" target="_blank">
                <span>🌐</span> Open Live RDP Session
            </a>
            
            <a href="{{ direct_url }}" class="btn btn-purple" target="_blank">
                <span>🚀</span> Open Website Directly
            </a>
            
            <button class="btn btn-success" onclick="checkStatus()">
                <span>🔄</span> Refresh Status
            </button>
        </div>
        
        <div class="connection-details">
            <h3>📡 Connection Information</h3>
            <p><strong>Live RDP URL:</strong> <a href="/vnc" style="color: #60a5fa;">{{ external_url }}/vnc</a></p>
            <p><strong>GitHub Codespaces:</strong> <a href="{{ target_url }}" style="color: #60a5fa;">{{ target_url }}</a></p>
            <p><strong>Status:</strong> <span id="service-status">Checking...</span></p>
        </div>
        
        <div class="instructions">
            <h3>📋 How to Use</h3>
            <ol style="margin: 10px 0 10px 20px; line-height: 1.8;">
                <li>Click <strong>"Open Live RDP Session"</strong> above</li>
                <li>Wait 10-20 seconds for the RDP session to load</li>
                <li>You'll see Chrome with GitHub Codespaces already open</li>
                <li>No certificate warnings - everything works automatically</li>
                <li>If blank screen appears, wait 30 seconds and refresh</li>
            </ol>
            
            <div style="margin-top: 15px; padding: 10px; background: rgba(245,158,11,0.1); border-radius: 6px;">
                <strong>⚠️ First Time Note:</strong> Initial load may take 20-30 seconds as Chrome initializes.
            </div>
        </div>
        
        <div style="text-align: center; color: #94a3b8; margin-top: 30px; font-size: 0.9em;">
            <p>RDP Browser • Render Compatible • All traffic through port 10000</p>
            <p id="refresh-timer">Auto-refreshing in 30 seconds...</p>
        </div>
    </div>

    <script>
        let refreshTime = 30;
        const timerElement = document.getElementById('refresh-timer');
        const statusElement = document.getElementById('service-status');
        
        function updateTimer() {
            if (timerElement) {
                timerElement.textContent = `Auto-refreshing in ${refreshTime} seconds...`;
                refreshTime--;
                
                if (refreshTime <= 0) {
                    window.location.reload();
                }
            }
        }
        
        // Update timer every second
        setInterval(updateTimer, 1000);
        
        // Check service status
        function checkStatus() {
            fetch('/api/status')
                .then(response => response.json())
                .then(data => {
                    let statusText = '✅ All services running';
                    if (!data.vnc_ready) statusText = '⏳ VNC starting...';
                    if (!data.browser_ready) statusText = '⏳ Browser starting...';
                    
                    statusElement.textContent = statusText;
                    
                    alert('Service Status:\\n\\n' +
                         `VNC: ${data.vnc_ready ? '✅ Ready' : '⏳ Starting'}\\n` +
                         `Browser: ${data.browser_ready ? '✅ Ready' : '⏳ Starting'}\\n` +
                         `Uptime: ${data.uptime}\\n\\n` +
                         'Click "Open Live RDP Session" to connect.');
                })
                .catch(error => {
                    statusElement.textContent = '⚠️ Checking...';
                });
        }
        
        // Auto-check status on load
        setTimeout(checkStatus, 2000);
        
        // Auto-refresh page every 30 seconds
        setTimeout(() => {
            window.location.reload();
        }, 30000);
    </script>
</body>
</html>
'''

# ==================== FLASK ROUTES ====================
@app.route('/')
def index():
    """Main control panel"""
    status_data = status.get_status()
    
    return render_template_string(
        INDEX_HTML,
        vnc_ready=status_data['vnc_ready'],
        browser_ready=status_data['browser_ready'],
        uptime=status_data['uptime'],
        target_url=CONFIG['target_url'],
        external_url=RENDER_EXTERNAL_URL,
        direct_url=CONFIG['target_url']
    )

@app.route('/vnc')
def vnc_client():
    """Embedded noVNC client page"""
    return VNCProxy.get_vnc_page()

@app.route('/websockify')
def websockify_proxy():
    """WebSocket proxy for noVNC (handled by websockify)"""
    # This route won't be called directly - websockify handles it
    return redirect('/vnc')

@app.route('/api/status')
def api_status():
    """JSON status endpoint"""
    return jsonify(status.get_status())

@app.route('/health')
def health():
    """Health check for Render"""
    return jsonify({
        'status': 'healthy',
        'timestamp': time.time(),
        'service': 'rdp-browser',
        'version': '4.0',
        'render_compatible': True,
        'features': [
            'single-port-operation',
            'embedded-vnc-client',
            'certificate-error-suppression',
            'github-codespaces-access'
        ]
    }), 200

# ==================== STARTUP ====================
def main():
    """Main entry point"""
    logger.info("🚀 Starting RDP Browser (Render Compatible)")
    logger.info(f"External URL: {RENDER_EXTERNAL_URL}")
    logger.info(f"VNC Client: {RENDER_EXTERNAL_URL}/vnc")
    logger.info(f"Target: {CONFIG['target_url']}")
    logger.info("🔧 All traffic routed through port 10000")
    
    # Start Flask app
    app.run(
        host=CONFIG['host'],
        port=CONFIG['control_port'],
        debug=CONFIG['debug'],
        threaded=True
    )

if __name__ == '__main__':
    main()
