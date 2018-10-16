FROM mintel/docker-alpine-bash-curl-jq:1.0.1

LABEL maintainer="Francesco Ciocchetti <fciocchetti@mintel.com>" \
      version="1.0.1" \
      vcs-url="https://github.com/mintel/docker-k8s-events-shipper"

RUN apk add --no-cache tini \
    && rm -rf /var/cache/apk/*

ADD docker-entrypoint.sh /
RUN chmod a+x /docker-entrypoint.sh
ADD wait-for-it.sh /
RUN chmod a+x /wait-for-it.sh
ADD healthz.sh /
RUN chmod a+x /healthz.sh

# Select STDOUT or NETCAT Mode
ENV OUTPUT_MODE stdout
# Select NETCAT Destination Host and port 
ENV NETCAT_DST_HOST 127.0.0.1
ENV NETCAT_DST_PORT 9000

ENTRYPOINT ["tini", "--", "/docker-entrypoint.sh"]
