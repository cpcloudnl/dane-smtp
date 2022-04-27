#!/bin/bash
#
# Finds the mailserver for a domain and validates the
# DANE TLSA record used for validation between MTA's.
#
# Optionally define the connecting port of the mail server
# defined in the MX record of the domain (defaults to 25).
#
# $ bash validate-dane-tlsa.sh "example.com" 25
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

# @TODO: multiple mailservers...
MAILSERVER=$(dig +short MX "$DOMAIN" | head -n 1 | awk '{print $2}')

if [[ -z "$MAILSERVER" ]]
then
    >&2 echo "ERROR: No MX-record found for domain: $DOMAIN"
    exit
fi

# https://stackoverflow.com/a/1898573
[[ "$MAILSERVER" =~ ([^.]*\.[a-z]+\.$) ]] && ROOT_DOMAIN="${BASH_REMATCH[1]}"

# @TODO: multiple nameservers...
NAMESERVER=$(dig +short NS "$ROOT_DOMAIN" | head -n 1)

DNSNAME="_$PORT._$PROTOCOL.$MAILSERVER"

DIGGED=$(dig +noall +answer -t TLSA "$ROOT_DOMAIN" "$DNSNAME" @"$NAMESERVER")

if [[ ! -z "$DIGGED" ]]
then
    TTL=$(echo "$DIGGED" | awk '{print $2}')
    USAGE=$(echo "$DIGGED" | awk '{print $5}')
    SELECTOR=$(echo "$DIGGED" | awk '{print $6}')
    MATCHTYPE=$(echo "$DIGGED" | awk '{print $7}')
    TLSA=$(echo "$DIGGED" | awk '{print $8$9}')
    
    CURRENT="$DNSNAME $TTL IN TLSA $USAGE $SELECTOR $MATCHTYPE $TLSA"
fi

GENERATED=$(bash get-dane-tlsa.sh "${MAILSERVER%?}" "$PORT")

if [[ "$GENERATED" != "$CURRENT" ]]
then
    if [[ -z "$CURRENT" ]]
    then
        >&2 echo "No TLSA record."
    else
        >&2 echo "Invalid TLSA record."
        >&2 echo "CURRENT RECORD:"
        >&2 echo "$CURRENT"
    fi

    >&2 echo "SUGGESTED RECORD:"
    >&2 echo "$GENERATED"
    exit
else
    echo "Valid TLSA record:"
    echo "$DIGGED"
fi
