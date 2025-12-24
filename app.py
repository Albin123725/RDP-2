from flask import Flask, render_template_string
import os

app = Flask(__name__)

HTML = '''
<!DOCTYPE html>
<html>
<head>
    <title>Lightweight Browser RDP</title>
    <style>
        body { margin: 0; padding: 20px; background: #0f172a; color: white; font-family: Arial; }
        .container { max-width: 1200px; margin: 0 auto; }
        .rdp-viewer { width: 100%; height: 600px; border: 2px solid #3b82f6; border-radius: 8px; }
        .info-box { background: #1e293b; padding: 15px; border-radius: 8px; margin: 15px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌐 Lightweight Browser RDP</h1>
        
        <div class="info-box">
            <h3>Connection Details:</h3>
            <p><strong>RDP Port:</strong> 3389</p>
            <p><strong>VNC Port:</strong> 5900</p>
            <p><strong>Username:</strong> browseruser</p>
            <p><strong>Password:</strong> password</p>
        </div>
        
        <div class="info-box">
            <h3>Access Methods:</h3>
            <p>1. <strong>Windows/Mac RDP Client:</strong> Connect to <code>YOUR_RENDER_URL:3389</code></p>
            <p>2. <strong>VNC Viewer:</strong> Connect to <code>YOUR_RENDER_URL:5900</code> (no password)</p>
            <p>3. <strong>Browser (below):</strong> Use noVNC web client</p>
        </div>
        
        <h3>Browser RDP Viewer:</h3>
        <iframe class="rdp-viewer" 
                src="https://novnc.com/noVNC/vnc.html?host=YOUR_RENDER_URL&port=5900&password=&autoconnect=true"
                allowfullscreen>
        </iframe>
        
        <div style="margin-top: 20px;">
            <button onclick="location.reload()" style="padding: 10px 20px; background: #3b82f6; color: white; border: none; border-radius: 5px; cursor: pointer;">
                Refresh Browser
            </button>
        </div>
    </div>
</body>
</html>
'''

@app.route('/')
def index():
    return HTML

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 10000))
    app.run(host='0.0.0.0', port=port, debug=False)
