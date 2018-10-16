#!/bin/sh

set -ex

KUBERNETES_SERVICE_HOST=${KUBERNETES_SERVICE_HOST:?Please specify KUBERNETES_SERVICE_HOST env variable}
KUBERNETES_SERVICE_PORT_HTTPS=${KUBERNETES_SERVICE_PORT_HTTPS:?Please specify KUBERNETES_SERVICE_PORT_HTTPS env variable}

BASE_URL="https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT_HTTPS}/api/v1"
CA_CERT="/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

RESOURCE_VERSION=$(curl -s "${BASE_URL}/events" --cacert "${CA_CERT}" -H "Authorization: Bearer ${TOKEN}" | jq -r '.metadata.resourceVersion')

if [ "x$OUTPUT_MODE" == "xstdout" ]; then
  curl -s "${BASE_URL}/watch/events?resourceVersion=${RESOURCE_VERSION}" --cacert "${CA_CERT}" -H "Authorization: Bearer ${TOKEN}" &
elif [ "x$OUTPUT_MODE" == "xnetcat" ]; then
  curl -s "${BASE_URL}/watch/events?resourceVersion=${RESOURCE_VERSION}" --cacert "${CA_CERT}" -H "Authorization: Bearer ${TOKEN}" | nc $NETCAT_DST_HOST $NETCAT_DST_PORT &
else
  echo "Unsupported mode $OUTPUT_MODE" >&2
  exit 1
fi

while true ; do
   tail -f /dev/null & wait ${!}
done
