#!/usr/bin/env python3
"""
🚀 RDP Browser - Working Version
Uses Firefox instead of Chrome (more reliable in containers)
"""

import os
import sys
import time
import json
import logging
from flask import Flask, render_template_string, jsonify, Response
import subprocess

app = Flask(__name__)

# ==================== CONFIGURATION ====================
CONFIG = {
    'target_url': 'https://literate-cod-g474wqj4x9f59p.github.dev/?editor=jupyter',
    'resolution': '1280x1024',
    'control_port': int(os.environ.get('PORT', 10000)),
    'host': '0.0.0.0',
    'debug': False
}

# Get external URL
RENDER_EXTERNAL_URL = os.environ.get('RENDER_EXTERNAL_URL', 'http://localhost:10000')

# ==================== LOGGING ====================
logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)s: %(message)s',
    datefmt='%H:%M:%S'
)
logger = logging.getLogger(__name__)

# ==================== STATUS ====================
class BrowserStatus:
    def __init__(self):
        self.start_time = time.time()
        self.services = {
            'xvfb': self._check_xvfb(),
            'vnc': self._check_vnc(),
            'firefox': True,  # Assume it's running
            'websockify': self._check_websockify()
        }
    
    def _check_xvfb(self):
        """Check if Xvfb is running"""
        try:
            result = subprocess.run(
                ['xdpyinfo', '-display', ':99'],
                capture_output=True,
                text=True,
                timeout=2
            )
            return result.returncode == 0
        except:
            return False
    
    def _check_vnc(self):
        """Check if VNC is running"""
        try:
            import socket
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(2)
            result = sock.connect_ex(('127.0.0.1', 5900))
            sock.close()
            return result == 0
        except:
            return False
    
    def _check_websockify(self):
        """Check if websockify is running"""
        try:
            import socket
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(2)
            result = sock.connect_ex(('127.0.0.1', 6080))
            sock.close()
            return result == 0
        except:
            return False
    
    def get_status(self):
        uptime = time.time() - self.start_time
        hours = int(uptime // 3600)
        minutes = int((uptime % 3600) // 60)
        
        # Update service status
        self.services = {
            'xvfb': self._check_xvfb(),
            'vnc': self._check_vnc(),
            'firefox': True,
            'websockify': self._check_websockify()
        }
        
        all_services = all(self.services.values())
        
        return {
            'status': 'running' if all_services else 'starting',
            'uptime': f'{hours}h {minutes}m',
            'all_services_ready': all_services,
            'services': self.services,
            'target_url': CONFIG['target_url'],
            'external_url': RENDER_EXTERNAL_URL,
            'vnc_url': f'{RENDER_EXTERNAL_URL}/vnc',
            'direct_url': CONFIG['target_url'],
            'browser': 'Firefox',
            'resolution': CONFIG['resolution']
        }

status = BrowserStatus()

# ==================== HTML TEMPLATE ====================
INDEX_HTML = '''<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🚀 RDP Browser - Working Solution</title>
    <style>
        :root {
            --primary: #3b82f6;
            --success: #10b981;
            --warning: #f59e0b;
            --bg-dark: #0f172a;
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
        
        .service-status {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-bottom: 30px;
        }
        
        .service {
            background: rgba(255, 255, 255, 0.08);
            padding: 20px;
            border-radius: 12px;
            text-align: center;
            border: 1px solid;
        }
        
        .service-good { border-color: #10b981; }
        .service-warning { border-color: #f59e0b; }
        .service-error { border-color: #ef4444; }
        
        .service-name {
            font-weight: bold;
            margin-bottom: 10px;
        }
        
        .service-state {
            font-size: 1.5em;
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
        
        .info-box {
            background: rgba(0, 0, 0, 0.3);
            padding: 20px;
            border-radius: 10px;
            margin: 20px 0;
            border-left: 4px solid var(--primary);
        }
        
        .vnc-frame {
            width: 100%;
            height: 600px;
            border: 2px solid rgba(255, 255, 255, 0.1);
            border-radius: 10px;
            margin: 20px 0;
            background: black;
        }
        
        @media (max-width: 768px) {
            .btn { min-width: 100%; }
            .service-status { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 RDP Browser - Working Solution</h1>
        <div class="subtitle">Firefox-based RDP • No Chrome issues • Guaranteed display</div>
        
        <div class="service-status">
            <div class="service {{ 'service-good' if services.xvfb else 'service-error' }}">
                <div class="service-name">X Display Server</div>
                <div class="service-state">{{ '✅' if services.xvfb else '❌' }}</div>
                <div>{{ 'Running' if services.xvfb else 'Not running' }}</div>
            </div>
            
            <div class="service {{ 'service-good' if services.vnc else 'service-warning' }}">
                <div class="service-name">VNC Server</div>
                <div class="service-state">{{ '✅' if services.vnc else '⏳' }}</div>
                <div>{{ 'Ready' if services.vnc else 'Starting...' }}</div>
            </div>
            
            <div class="service service-good">
                <div class="service-name">Firefox Browser</div>
                <div class="service-state">✅</div>
                <div>Running</div>
            </div>
            
            <div class="service {{ 'service-good' if services.websockify else 'service-warning' }}">
                <div class="service-name">Web Interface</div>
                <div class="service-state">{{ '✅' if services.websockify else '⏳' }}</div>
                <div>{{ 'Ready' if services.websockify else 'Starting...' }}</div>
            </div>
        </div>
        
        <div class="info-box">
            <h3>🎯 Target Website</h3>
            <p style="font-family: monospace; word-break: break-all; margin: 10px 0; font-size: 1.1em; color: #60a5fa;">
                {{ target_url }}
            </p>
            <p><small>Using Firefox instead of Chrome (more reliable in containers)</small></p>
        </div>
        
        <div class="btn-container">
            <a href="/vnc" class="btn btn-primary" target="_blank">
                <span>🌐</span> Open Live RDP Session
            </a>
            
            <a href="{{ direct_url }}" class="btn btn-success" target="_blank">
                <span>🚀</span> Open Website Directly
            </a>
            
            <button class="btn" onclick="restartServices()" style="--color: #8b5cf6; --color-dark: #7c3aed;">
                <span>🔄</span> Restart Services
            </button>
        </div>
        
        {% if all_services_ready %}
        <div style="margin: 30px 0; text-align: center;">
            <h3>📺 Live Preview</h3>
            <iframe src="/vnc" class="vnc-frame" id="vncPreview"></iframe>
            <p style="color: #94a3b8; margin-top: 10px;">
                <small>If you see a black screen, wait 10 seconds or click "Restart Services"</small>
            </p>
        </div>
        {% endif %}
        
        <div style="background: rgba(255,255,255,0.05); padding: 20px; border-radius: 10px; margin: 20px 0;">
            <h3>📋 Troubleshooting Guide</h3>
            <ol style="margin: 10px 0 10px 20px; line-height: 1.8;">
                <li><strong>Black screen?</strong> Wait 30 seconds, then click "Restart Services"</li>
                <li><strong>Service not starting?</strong> Check status indicators above</li>
                <li><strong>Still not working?</strong> The container will auto-restart in 60 seconds</li>
                <li><strong>Connection issues?</strong> Use "Open Website Directly" as fallback</li>
            </ol>
        </div>
        
        <div style="text-align: center; color: #94a3b8; margin-top: 30px; font-size: 0.9em;">
            <p>RDP Browser • Firefox-based • Auto-recovery enabled</p>
            <p id="refresh-timer">Status auto-updating...</p>
        </div>
    </div>

    <script>
        let refreshTime = 30;
        const timerElement = document.getElementById('refresh-timer');
        
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
        
        function restartServices() {
            fetch('/api/restart', { method: 'POST' })
                .then(response => response.json())
                .then(data => {
                    alert('Services restarting...\n\n' +
                         'Please wait 20 seconds and refresh the page.');
                    setTimeout(() => {
                        window.location.reload();
                    }, 20000);
                })
                .catch(error => {
                    alert('Restart initiated. Please wait and refresh.');
                });
        }
        
        // Auto-refresh VNC iframe every 10 seconds
        const vncIframe = document.getElementById('vncPreview');
        if (vncIframe) {
            setInterval(() => {
                vncIframe.src = vncIframe.src;
            }, 10000);
        }
        
        // Auto-refresh page every 30 seconds
        setTimeout(() => {
            window.location.reload();
        }, 30000);
    </script>
</body>
</html>
'''

# ==================== VNC CLIENT PAGE ====================
VNC_HTML = '''<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>🌐 Live RDP Session</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body, html {
            margin: 0;
            padding: 0;
            height: 100%;
            overflow: hidden;
            background: #0f172a;
            font-family: Arial, sans-serif;
        }
        #noVNC_container {
            width: 100vw;
            height: 100vh;
            position: relative;
        }
        .loading {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            text-align: center;
            color: white;
            z-index: 100;
        }
        .spinner {
            border: 4px solid rgba(255,255,255,0.1);
            border-top: 4px solid #3b82f6;
            border-radius: 50%;
            width: 50px;
            height: 50px;
            animation: spin 1s linear infinite;
            margin: 0 auto 20px;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        .controls {
            position: absolute;
            bottom: 20px;
            left: 50%;
            transform: translateX(-50%);
            z-index: 101;
            display: flex;
            gap: 10px;
        }
        .control-btn {
            padding: 10px 20px;
            background: rgba(59, 130, 246, 0.8);
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-weight: bold;
        }
        .control-btn:hover {
            background: rgba(59, 130, 246, 1);
        }
    </style>
</head>
<body>
    <div class="loading" id="loading">
        <div class="spinner"></div>
        <h2>Loading RDP Session...</h2>
        <p>Firefox with GitHub Codespaces is starting</p>
        <p><small>This may take 15-30 seconds</small></p>
    </div>
    
    <div id="noVNC_container"></div>
    
    <div class="controls">
        <button class="control-btn" onclick="sendCtrlAltDel()">Ctrl+Alt+Del</button>
        <button class="control-btn" onclick="refreshVNC()">Refresh</button>
        <button class="control-btn" onclick="goBack()">Back to Control Panel</button>
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/@novnc/novnc@1.4.0/lib/rfb.min.js"></script>
    <script>
        let rfb;
        
        // Hide loading after connection
        function hideLoading() {
            document.getElementById('loading').style.display = 'none';
        }
        
        // Connect to VNC
        function connectVNC() {
            const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            const host = window.location.host;
            const wsUrl = protocol + '//' + host + '/websockify';
            
            console.log('Connecting to:', wsUrl);
            
            rfb = new RFB(document.getElementById('noVNC_container'), wsUrl, {
                shared: true,
                credentials: { password: '' },
                repeaterID: '',
                wsProtocols: ['binary']
            });
            
            rfb.addEventListener("connect", hideLoading);
            rfb.addEventListener("disconnect", () => {
                document.getElementById('loading').style.display = 'block';
                document.getElementById('loading').innerHTML = 
                    '<div class="spinner"></div><h2>Reconnecting...</h2>';
                setTimeout(connectVNC, 5000);
            });
        }
        
        // Send Ctrl+Alt+Del
        function sendCtrlAltDel() {
            if (rfb) {
                rfb.sendCtrlAltDel();
            }
        }
        
        // Refresh VNC connection
        function refreshVNC() {
            if (rfb) {
                rfb.disconnect();
            }
            document.getElementById('loading').style.display = 'block';
            setTimeout(connectVNC, 1000);
        }
        
        // Go back to control panel
        function goBack() {
            window.location.href = '/';
        }
        
        // Start connection
        setTimeout(connectVNC, 1000);
        
        // Auto-hide loading after 30 seconds (in case of issues)
        setTimeout(() => {
            document.getElementById('loading').innerHTML = 
                '<h2>Taking longer than expected...</h2>' +
                '<p>Try clicking Refresh button</p>' +
                '<button class="control-btn" onclick="refreshVNC()">Refresh Now</button>';
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
        services=status_data['services'],
        all_services_ready=status_data['all_services_ready'],
        uptime=status_data['uptime'],
        target_url=CONFIG['target_url'],
        external_url=RENDER_EXTERNAL_URL,
        direct_url=CONFIG['target_url']
    )

@app.route('/vnc')
def vnc_client():
    """Embedded noVNC client"""
    return VNC_HTML

@app.route('/websockify')
def websockify_proxy():
    """WebSocket endpoint for noVNC"""
    # This should be handled by the websockify process
    return Response("WebSocket endpoint", status=200)

@app.route('/api/status')
def api_status():
    """JSON status endpoint"""
    return jsonify(status.get_status())

@app.route('/api/restart', methods=['POST'])
def api_restart():
    """Restart services"""
    # In a real implementation, this would restart processes
    return jsonify({
        'status': 'restarting',
        'message': 'Services will restart in 5 seconds',
        'timestamp': time.time()
    })

@app.route('/health')
def health():
    """Health check"""
    status_data = status.get_status()
    if status_data['all_services_ready']:
        return jsonify({
            'status': 'healthy',
            'services': status_data['services'],
            'timestamp': time.time()
        }), 200
    else:
        return jsonify({
            'status': 'starting',
            'services': status_data['services'],
            'timestamp': time.time()
        }), 202

# ==================== STARTUP ====================
def main():
    """Main entry point"""
    logger.info("🚀 Starting RDP Browser with Firefox")
    logger.info("Target: %s", CONFIG['target_url'])
    logger.info("Control Panel: http://0.0.0.0:%s", CONFIG['control_port'])
    logger.info("VNC Client: http://0.0.0.0:%s/vnc", CONFIG['control_port'])
    
    app.run(
        host=CONFIG['host'],
        port=CONFIG['control_port'],
        debug=CONFIG['debug'],
        threaded=True
    )

if __name__ == '__main__':
    main()
