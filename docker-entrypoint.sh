#!/bin/sh

set -ex

KUBERNETES_SERVICE_HOST=${KUBERNETES_SERVICE_HOST:?Please specify KUBERNETES_SERVICE_HOST env variable}
KUBERNETES_SERVICE_PORT_HTTPS=${KUBERNETES_SERVICE_PORT_HTTPS:?Please specify KUBERNETES_SERVICE_PORT_HTTPS env variable}

BASE_URL="https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT_HTTPS}/api/v1"
CA_CERT="/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

# SIGTERM-handler
term_handler() {
  if [ ! -z $CURL_PID ] && [ $CURL_PID -ne 0 ]; then
    set +e
    kill -9 "$CURL_PID" # SIGTERM
    wait "$CURL_PID"
    set -e
  fi
  if [ $PID -ne 0 ]; then
    set +e
    kill -9 "$PID" # SIGTERM
    wait "$PID"
    set -e
  fi
  exit 0;
  #exit 143; # 128 + 15 -- SIGTERM
}


# Trap the TERM Signals
trap 'kill ${!}; term_handler' SIGTERM

RESOURCE_VERSION=$(curl -s "${BASE_URL}/events" --cacert "${CA_CERT}" -H "Authorization: Bearer ${TOKEN}" | jq -r '.metadata.resourceVersion')

if [ "x$OUTPUT_MODE" == "xstdout" ]; then
  curl -s "${BASE_URL}/watch/events?resourceVersion=${RESOURCE_VERSION}" --cacert "${CA_CERT}" -H "Authorization: Bearer ${TOKEN}" &
  PID=$!
  CURL_PID=""
elif [ "x$OUTPUT_MODE" == "xnetcat" ]; then
  ( curl -s "${BASE_URL}/watch/events?resourceVersion=${RESOURCE_VERSION}" --cacert "${CA_CERT}" -H "Authorization: Bearer ${TOKEN}" & echo $! > /tmp/curl.pid) | nc $NETCAT_DST_HOST $NETCAT_DST_PORT &
  PID=$!
  CURL_PID=$(cat /tmp/curl.pid)
else
  echo "Unsupported mode $OUTPUT_MODE" >&2
  exit 1
fi

while true ; do
   tail -f /dev/null & wait ${!}
done
