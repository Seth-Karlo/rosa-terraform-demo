#!/bin/bash

THUMBPRINT=$(echo | openssl s_client -servername $1 -showcerts -connect $1:443 2>&- | \
    tail -r | \
    sed -n '/-----END CERTIFICATE-----/,/-----BEGIN CERTIFICATE-----/p; /-----BEGIN CERTIFICATE-----/q' | \
    tail -r | \
    openssl x509 -fingerprint -sha1 -noout | \
    sed 's/://g' | awk -F= '{print tolower($2)}')
THUMBPRINT_JSON="{\"thumbprint\": \"${THUMBPRINT}\"}"
echo $THUMBPRINT_JSON
