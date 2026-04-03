FROM alpine:3.19

# Dump FULL content of both config files and compare
RUN echo "=== FULL /etc/docker/config.json ===" && \
    cat /etc/docker/config.json 2>&1 | od -A x -t x1z | head -100 && \
    echo "=== FULL /kaniko/.docker/config.json ===" && \
    cat /kaniko/.docker/config.json 2>&1 | od -A x -t x1z | head -100 && \
    echo "=== DIFF ===" && \
    diff /etc/docker/config.json /kaniko/.docker/config.json 2>&1 || true && \
    echo "=== MD5 ===" && \
    md5sum /etc/docker/config.json /kaniko/.docker/config.json 2>&1 || true && \
    echo "=== FILE SIZES ===" && \
    wc -c /etc/docker/config.json /kaniko/.docker/config.json 2>&1 || true && \
    echo "=== END ==="

RUN apk add --no-cache python3
COPY server.py /server.py
EXPOSE 8080
CMD ["python3", "/server.py"]
