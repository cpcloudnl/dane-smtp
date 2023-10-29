#!/bin/bash
#
# Fetches and prints the end certificate of a domain.
# Optionally define the connecting port (25 by default).
#
# $ bash get-cert.sh "mx.example.com" 25
#
DOMAIN="$1"
PORT="$2"

if [[ -z "$DOMAIN" ]]
then
    >&2 echo "ERROR: No domain defined."
    exit
fi

if [[ -z "$PORT" ]]
then
    PORT="25"
fi

CRTDATA=$(openssl s_client -connect "$DOMAIN:$PORT" -servername "$DOMAIN" -starttls smtp </dev/null 2>/dev/null)

echo "$CRTDATA" | openssl x509
