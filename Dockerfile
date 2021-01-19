FROM alpine:3

RUN apk add --no-cache wget curl \
    && wget -O speedtest-cli.tgz https://bintray.com/ookla/download/download_file?file_path=ookla-speedtest-1.0.0-arm-linux.tgz \
    && tar zxvf speedtest-cli.tgz \
    && rm speedtest-cli.tgz \
    && mv speedtest* /usr/bin/

# HEALTHCHECK --interval=5m --timeout=5s --retries=1 \
#    CMD ./healthcheck.sh

WORKDIR /opt/speedtest

ADD scripts/ .

RUN chmod +x ./init_test_connection.sh \
    && chmod +x ./healthcheck.sh

CMD ./init_test_connection.sh
