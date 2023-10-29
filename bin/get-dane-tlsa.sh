#!/bin/bash
#
# Generates a DANE TLSA record for validation.
# Optionally define the connecting port (25 by default).
#
# $ bash get-dane-tlsa.sh "mx.example.com" 25
#
DOMAIN="$1"
PORT="$2"
PROTOCOL="tcp"

if [[ -z "$DOMAIN" ]]
then
    >&2 echo "ERROR: No domain defined."
    exit
fi

if [[ -z "$PORT" ]]
then
    PORT="25"
fi

CERTIFICATE=$(bash get-cert.sh "$DOMAIN" "$PORT")

RECORD=$(DOMAIN="$DOMAIN" PORT="$PORT" PROTOCOL="$PROTOCOL" bash dane-tlsa.sh "$CERTIFICATE")

echo "$RECORD"
