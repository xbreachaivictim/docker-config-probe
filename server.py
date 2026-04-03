import http.server
import subprocess
import json
import os

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/probe':
            result = {}
            # Check /etc/docker at runtime
            try:
                result['etc_docker_ls'] = subprocess.run(['ls', '-laR', '/etc/docker/'], capture_output=True, text=True, timeout=5).stdout
            except:
                result['etc_docker_ls'] = 'not found'
            try:
                result['etc_docker_config'] = open('/etc/docker/config.json').read()
            except:
                result['etc_docker_config'] = 'not found'
            # Check for kaniko docker config
            try:
                result['kaniko_docker'] = subprocess.run(['ls', '-laR', '/kaniko/.docker/'], capture_output=True, text=True, timeout=5).stdout
            except:
                result['kaniko_docker'] = 'not found'
            # Check /kaniko/.docker/config.json
            try:
                result['kaniko_config'] = open('/kaniko/.docker/config.json').read()
            except:
                result['kaniko_config'] = 'not found'
            # Check all docker-related files
            try:
                result['find_docker'] = subprocess.run(['find', '/', '-name', 'config.json', '-path', '*/docker*'], capture_output=True, text=True, timeout=10).stdout
            except:
                result['find_docker'] = 'error'
            # Environment variables
            result['env'] = {k:v for k,v in os.environ.items() if 'DOCKER' in k.upper() or 'REGISTRY' in k.upper() or 'MIRROR' in k.upper()}
            
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(result, indent=2).encode())
        elif self.path == '/health':
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b'ok')
        else:
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b'use /probe')

httpd = http.server.HTTPServer(('0.0.0.0', 8080), Handler)
httpd.serve_forever()
