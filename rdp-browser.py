#!/usr/bin/env python3
"""
🚀 ULTRA-MINIMAL RDP BROWSER - SIMPLIFIED
Single-app RDP with only browser - No psutil dependency
"""

import os
import sys
import time
import json
import signal
import logging
from flask import Flask, render_template_string, jsonify

# Add virtual environment path
venv_path = '/app/venv/lib/python3.12/site-packages'
if os.path.exists(venv_path):
    sys.path.insert(0, venv_path)

app = Flask(__name__)

# ==================== CONFIGURATION ====================
CONFIG = {
    'target_url': 'https://literate-cod-g474wqj4x9f59p.github.dev/?editor=jupyter',
    'resolution': '1024x768',
    'vnc_port': 5901,
    'web_port': 6081,
    'control_port': int(os.environ.get('PORT', 10000)),
    'host': '0.0.0.0',
    'debug': False
}

# ==================== LOGGING ====================
logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)s: %(message)s',
    datefmt='%H:%M:%S'
)
logger = logging.getLogger(__name__)

# ==================== SIMPLE STATUS ====================
class SimpleStatus:
    def __init__(self):
        self.start_time = time.time()
        self.estimate_memory = 150  # Estimated MB
    
    def get_uptime(self):
        return time.time() - self.start_time
    
    def get_uptime_hours(self):
        return round(self.get_uptime() / 3600, 1)
    
    def get_status(self):
        return {
            'status': 'running',
            'uptime': self.get_uptime(),
            'uptime_hours': self.get_uptime_hours(),
            'memory_mb': self.estimate_memory,
            'target_url': CONFIG['target_url'],
            'vnc_port': CONFIG['vnc_port'],
            'web_port': CONFIG['web_port'],
            'resolution': CONFIG['resolution']
        }

status = SimpleStatus()

# ==================== HTML TEMPLATE ====================
INDEX_HTML = '''<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🚀 Ultra-Minimal RDP Browser</title>
    <style>
        :root {
            --primary: #3b82f6;
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
            max-width: 900px;
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
        
        .stats {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 15px;
            margin-bottom: 30px;
        }
        
        .stat {
            background: rgba(255, 255, 255, 0.08);
            padding: 20px;
            border-radius: 12px;
            text-align: center;
        }
        
        .stat-value {
            font-size: 2em;
            font-weight: bold;
            color: #10b981;
            margin-bottom: 5px;
        }
        
        .btn {
            padding: 15px 30px;
            background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%);
            color: white;
            border: none;
            border-radius: 10px;
            cursor: pointer;
            font-weight: 600;
            margin: 10px;
            transition: all 0.3s;
            display: inline-flex;
            align-items: center;
            gap: 10px;
        }
        
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(37, 99, 235, 0.4);
        }
        
        .url-box {
            background: rgba(0, 0, 0, 0.3);
            padding: 15px;
            border-radius: 10px;
            margin: 20px 0;
            font-family: monospace;
            word-break: break-all;
            border-left: 4px solid var(--primary);
        }
        
        .connection-info {
            background: rgba(59, 130, 246, 0.1);
            padding: 20px;
            border-radius: 10px;
            margin: 20px 0;
        }
        
        @media (max-width: 768px) {
            .stats { grid-template-columns: 1fr; }
            .btn { width: 100%; margin: 5px 0; }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Ultra-Minimal RDP Browser</h1>
        <div class="subtitle">Single-app RDP • Only Browser • Ready to Use</div>
        
        <div class="stats">
            <div class="stat">
                <div class="stat-value">{{memory_mb}} MB</div>
                <div>Estimated Memory</div>
            </div>
            <div class="stat">
                <div class="stat-value">{{uptime_hours}}h</div>
                <div>Uptime</div>
            </div>
            <div class="stat">
                <div class="stat-value">✅</div>
                <div>Status: Running</div>
            </div>
        </div>
        
        <div class="url-box">
            <strong>🎯 Target Website:</strong><br>
            {{target_url}}
        </div>
        
        <div class="connection-info">
            <h3>📡 Connection Methods</h3>
            <p><strong>🌐 Web VNC:</strong> {{web_vnc_url}}</p>
            <p><strong>🔗 Direct VNC:</strong> {{hostname}}:{{vnc_port}} (no password)</p>
            <p><strong>⚙️ Resolution:</strong> {{resolution}}</p>
        </div>
        
        <div style="text-align: center; margin: 30px 0;">
            <button class="btn" onclick="openWebVNC()">
                <span>🌐</span> Open Web VNC
            </button>
            
            <button class="btn" onclick="openDirectLink()">
                <span>🚀</span> Open Website Directly
            </button>
            
            <button class="btn" onclick="refreshPage()">
                <span>🔄</span> Refresh Status
            </button>
        </div>
        
        <div style="text-align: center; color: #94a3b8; margin-top: 30px;">
            <p>Browser is pre-loaded with target website. Connect via VNC to access.</p>
        </div>
    </div>

    <script>
        function openWebVNC() {
            window.open('{{web_vnc_url}}', '_blank');
        }
        
        function openDirectLink() {
            window.open('{{target_url}}', '_blank');
        }
        
        function refreshPage() {
            window.location.reload();
        }
        
        // Auto-refresh every 60 seconds
        setTimeout(() => {
            window.location.reload();
        }, 60000);
    </script>
</body>
</html>
'''

# ==================== FLASK ROUTES ====================
@app.route('/')
def index():
    """Main control panel"""
    hostname = os.environ.get('RENDER_EXTERNAL_HOSTNAME', 'localhost')
    
    status_data = status.get_status()
    
    return render_template_string(
        INDEX_HTML,
        memory_mb=status_data['memory_mb'],
        uptime_hours=status_data['uptime_hours'],
        target_url=CONFIG['target_url'],
        web_vnc_url=f"http://{hostname}:{CONFIG['web_port']}/vnc.html",
        hostname=hostname,
        vnc_port=CONFIG['vnc_port'],
        resolution=CONFIG['resolution']
    )

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
        'service': 'ultra-minimal-rdp-browser',
        'version': '2.0'
    }), 200

@app.route('/ping')
def ping():
    """Simple ping endpoint"""
    return 'pong', 200

# ==================== STARTUP ====================
def main():
    """Main entry point"""
    # Log startup
    logger.info("🚀 Starting Ultra-Minimal RDP Browser")
    logger.info(f"Control Panel: http://0.0.0.0:{CONFIG['control_port']}")
    logger.info(f"Web VNC Port: {CONFIG['web_port']}")
    logger.info(f"VNC Port: {CONFIG['vnc_port']}")
    logger.info(f"Target: {CONFIG['target_url']}")
    
    # Start Flask app
    app.run(
        host=CONFIG['host'],
        port=CONFIG['control_port'],
        debug=CONFIG['debug'],
        threaded=True
    )

if __name__ == '__main__':
    main()
