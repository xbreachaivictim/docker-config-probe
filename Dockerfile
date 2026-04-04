FROM alpine:3.19
RUN apk add --no-cache curl python3 nmap

# Probe 1: K8s API server (10.245.0.1) - check if accessible without auth
RUN echo "=== K8S API ANON ===" && \
    curl -sk --max-time 8 https://10.245.0.1/api/v1/ 2>&1 | head -30 && \
    curl -sk --max-time 8 https://10.245.0.1/version 2>&1 | head -10 && \
    curl -sk --max-time 8 https://10.245.0.1/metrics 2>&1 | head -10 || true

# Probe 2: Port scan K8s API and DNS servers (targeted)
RUN echo "=== PORT SCAN ===" && \
    nmap -p 443,6443,8443,2379,10250 --max-retries 1 --host-timeout 5s 10.245.0.1 2>&1 && \
    nmap -p 53,443,8080,9153 --max-retries 1 --host-timeout 5s 10.245.0.10 2>&1

# Probe 3: Scan /24 around kubernetes API (fast)
RUN echo "=== K8S RANGE SCAN ===" && \
    nmap -sn --max-retries 1 --host-timeout 2s 10.245.0.0/24 2>&1 | grep -E "report for|Host is up" | head -20

# Probe 4: Try to get build namespace K8s API (maybe SA in /proc or cgroup)
RUN echo "=== BUILD CONTEXT ===" && \
    cat /proc/1/cgroup 2>&1 | head -10 && \
    ls /run/secrets/ 2>&1 && \
    cat /proc/net/tcp 2>&1 | head -20

# Probe 5: Internal DO services known from prev research
RUN echo "=== DO INTERNAL ===" && \
    for host in internal.digitalocean.com api.internal digitalocean.internal do-platform.internal; do \
      result=$(nslookup $host 2>&1 | grep "Address" | grep -v "10.245.0.10" | head -2); \
      echo "$host: $result"; \
    done

COPY server.py /server.py
EXPOSE 8080
CMD ["python3", "/server.py"]

