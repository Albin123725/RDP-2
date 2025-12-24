from flask import Flask, redirect
import os

app = Flask(__name__)

@app.route('/')
def index():
    """Redirect to noVNC interface"""
    # Get the correct URL (Render provides RENDER_EXTERNAL_URL)
    base_url = os.environ.get('RENDER_EXTERNAL_URL', 'http://localhost:8080')
    return redirect(f"{base_url}/vnc.html")

@app.route('/health')
def health():
    """Health check for Render"""
    return "OK", 200

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port)
