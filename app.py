#!/usr/bin/env python3
"""
🚀 Direct Web RDP Interface
Access your RDP browser directly via Render URL
"""

from flask import Flask, render_template_string, jsonify
import os
import time

app = Flask(__name__)

# Get Render external URL
RENDER_EXTERNAL_URL = os.environ.get('RENDER_EXTERNAL_URL', 'http://localhost:10000')

HTML = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🚀 Direct RDP Browser</title>
    <style>
        :root {
            --primary: #3b82f6;
            --success: #10b981;
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
            max-width: 1200px;
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
        
        .vnc-container {
            width: 100%;
            height: 600px;
            border: 2px solid rgba(255, 255, 255, 0.1);
            border-radius: 10px;
            overflow: hidden;
            margin: 20px 0;
            background: black;
        }
        
        .controls {
            display: flex;
            gap: 15px;
            flex-wrap: wrap;
            justify-content: center;
            margin: 20px 0;
        }
        
        .btn {
            padding: 12px 24px;
            background: linear-gradient(135deg, var(--color) 0%, var(--color-dark) 100%);
            color: white;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-weight: 600;
            font-size: 14px;
            transition: all 0.3s;
        }
        
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(0, 0, 0, 0.3);
        }
        
        .btn-primary { --color: #3b82f6; --color-dark: #1d4ed8; }
        .btn-success { --color: #10b981; --color-dark: #059669; }
        
        .status {
            background: rgba(255, 255, 255, 0.08);
            padding: 15px;
            border-radius: 10px;
            margin: 20px 0;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .status-dot {
            width: 10px;
            height: 10px;
            border-radius: 50%;
            background: var(--success);
        }
        
        @media (max-width: 768px) {
            .vnc-container { height: 400px; }
            .btn { width: 100%; }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Direct RDP Browser</h1>
        <div class="subtitle">Access Chrome browser directly via this page • No extra ports needed</div>
        
        <div class="status">
            <div class="status-dot"></div>
            <div>✅ RDP Session Ready - Chrome browser is running</div>
        </div>
        
        <div class="vnc-container" id="vncContainer">
            <!-- noVNC will be embedded here -->
        </div>
        
        <div class="controls">
            <button class="btn btn-primary" onclick="connectVNC()">
                🔗 Connect to Browser
            </button>
            <button class="btn btn-success" onclick="openNewTab()">
                🌐 Open in New Tab
            </button>
            <button class="btn" onclick="refreshConnection()" style="--color: #8b5cf6; --color-dark: #7c3aed;">
                🔄 Refresh
            </button>
        </div>
        
        <div style="margin-top: 30px; padding: 15px; background: rgba(255,255,255,0.05); border-radius: 10px;">
            <h3>📋 How to Use:</h3>
            <ol style="margin: 10px 0 10px 20px; line-height: 1.8;">
                <li>Click <strong>"Connect to Browser"</strong> above</li>
                <li>Wait 5-10 seconds for the browser to load</li>
                <li>Use Chrome as if it were on your local machine</li>
                <li>Bookmark this page for direct access</li>
            </ol>
        </div>
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/@novnc/novnc@1.4.0/lib/rfb.min.js"></script>
    <script>
        let rfb;
        
        function connectVNC() {
            // Hide any existing connection
            if (rfb) {
                rfb.disconnect();
            }
            
            // Create WebSocket URL
            const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            const host = window.location.host;
            const wsUrl = protocol + '//' + host + '/websockify';
            
            console.log('Connecting to:', wsUrl);
            
            // Connect to noVNC
            rfb = new RFB(document.getElementById('vncContainer'), wsUrl, {
                shared: true,
                credentials: { password: '' },
                repeaterID: '',
                wsProtocols: ['binary']
            });
            
            rfb.addEventListener("connect", () => {
                console.log('✅ Connected to RDP session');
                showMessage('Connected! Chrome browser is ready.');
            });
            
            rfb.addEventListener("disconnect", () => {
                console.log('Disconnected');
                showMessage('Disconnected. Click "Connect to Browser" to reconnect.');
            });
        }
        
        function openNewTab() {
            // Open VNC in new tab
            const vncUrl = window.location.origin + '/vnc.html';
            window.open(vncUrl, '_blank');
        }
        
        function refreshConnection() {
            if (rfb) {
                rfb.disconnect();
            }
            setTimeout(connectVNC, 1000);
        }
        
        function showMessage(msg) {
            const container = document.getElementById('vncContainer');
            container.innerHTML = `<div style="padding: 20px; text-align: center; color: white;">${msg}</div>`;
        }
        
        // Auto-connect after 1 second
        setTimeout(connectVNC, 1000);
        
        // Auto-reconnect if disconnected
        setInterval(() => {
            if (rfb && !rfb._connected) {
                console.log('Auto-reconnecting...');
                connectVNC();
            }
        }, 10000);
    </script>
</body>
</html>
'''

@app.route('/')
def index():
    """Main web interface"""
    return render_template_string(HTML)

@app.route('/vnc.html')
def vnc_html():
    """Direct VNC client page"""
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <title>🚀 RDP Browser - Full Screen</title>
        <meta charset="UTF-8">
        <style>
            body, html { margin: 0; padding: 0; height: 100%; overflow: hidden; }
            #noVNC_container { width: 100vw; height: 100vh; }
        </style>
        <script src="https://cdn.jsdelivr.net/npm/@novnc/novnc@1.4.0/lib/rfb.min.js"></script>
    </head>
    <body>
        <div id="noVNC_container"></div>
        <script>
            const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            const host = window.location.host;
            const wsUrl = protocol + '//' + host + '/websockify';
            
            const rfb = new RFB(document.getElementById('noVNC_container'), wsUrl, {
                shared: true,
                credentials: { password: '' }
            });
        </script>
    </body>
    </html>
    '''

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'direct-rdp-browser',
        'timestamp': time.time()
    }), 200

@app.route('/status')
def status():
    """Status endpoint"""
    return jsonify({
        'status': 'running',
        'vnc_port': 5900,
        'websocket_port': 6080,
        'web_interface': 'ready'
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 10000))
    app.run(host='0.0.0.0', port=port, debug=False)
