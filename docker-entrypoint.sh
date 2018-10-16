#!/bin/sh
set -x
KUBERNETES_SERVICE_HOST=${KUBERNETES_SERVICE_HOST:?Please specify KUBERNETES_SERVICE_HOST env variable}
KUBERNETES_SERVICE_PORT_HTTPS=${KUBERNETES_SERVICE_PORT_HTTPS:?Please specify KUBERNETES_SERVICE_PORT_HTTPS env variable}

BASE_URL="https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT_HTTPS}/api/v1"
CA_CERT="/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

trap 'kill -TERM $PID $CURL_PID' TERM INT
while true; do
  # curl exits from time to time, most probably because of kube-proxy reloads iptables rules, needs deeper investigation. As for now, let's use a loop trick.
  RESOURCE_VERSION=$(curl -s "${BASE_URL}/events" --cacert "${CA_CERT}" -H "Authorization: Bearer ${TOKEN}" | jq -r '.metadata.resourceVersion')
  DATE=$(date --utc +"%Y-%m-%dT%TZ")
  echo "{\"time\":\"${DATE}\",\"object\":{\"message\":\"Monitoring Kubernetes events staring from ${RESOURCE_VERSION} resourceVersion\"}}" >&2

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
  wait $PID
done
