FROM alpine:3.19

RUN apk add --no-cache python3
COPY server.py /server.py
EXPOSE 8080
CMD ["python3", "/server.py"]

