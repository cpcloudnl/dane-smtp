#!/bin/bash
#
# $ bash dane-tlsa.sh "/path/to/cert.pem" 0|1 [ SHA256|SHA512 ]
#
CERTIFICATE="$1"
SELECTOR="$2"
USEHASH="$3"

if [[ -z "$CERTIFICATE" ]]
then
    >&2 echo "ERROR: No path to certificate defined."
    exit
fi

#
# Using selector type 0 is a better option from a security perspective.
#
# (0) Full certificate: the Certificate binary structure as defined in [RFC5280]
# (1) SubjectPublicKeyInfo: DER-encoded binary structure as defined in [RFC5280]
#
# @see https://datatracker.ietf.org/doc/html/rfc6698#section-2.1.2
# @see https://datatracker.ietf.org/doc/html/rfc6698#appendix-A.1.2.2
#
if [[ "$SELECTOR" != "0" && "$SELECTOR" != "1" ]]
then
    >&2 echo "ERROR: Selector must be: '1' (public key) or '0' (full cert.), got: '$SELECTOR'"
    exit
fi

#
# Having the record use the same hash algorithm that was used in the certs
# signature will assist clients that support a small number of algorithms.
#
# (0) Exact match on selected content: No hash used [RFC 6698]
# (1) SHA256 hash of selected content: SHA-256 [RFC 6234]
# (2) SHA512 hash of selected content: SHA-512 [RFC 6234]
#
# @see https://datatracker.ietf.org/doc/html/rfc6698#section-2.1.3
#
if [[ -z "$USEHASH" ]]
then
    # Exact match.
    DIGEST=""
    MATCHTYPE="0"
else
    if [[ "$USEHASH" != "SHA512" && "$USEHASH" != "SHA256" ]]
    then
        >&2 echo "ERROR: Hash must be: 'SHA256', 'SHA512' or undefined, got: '$USEHASH'"
        exit
    fi

    if [[ "$USEHASH" == "SHA512" ]]
    then
        DIGEST="-sha512"
        MATCHTYPE="2"
    else
        DIGEST="-sha256"
        MATCHTYPE="1"
    fi
fi

#
# openssl
#
if [[ "$SELECTOR" == "1" ]]
then
    TLSA="-noout -pubkey | openssl pkey -pubin "
fi

TLSA="$TLSA-outform DER"

if [[ ! -z "$DIGEST" ]]
then
    TLSA="$TLSA | openssl dgst $DIGEST -binary"
fi

if [[ -f "$CERTIFICATE" ]]
then
    TLSA="openssl x509 -in \"$CERTIFICATE\" $TLSA"
else
    TLSA="echo \"\$CERTIFICATE\" | openssl x509 $TLSA"
fi

TLSA=$(eval $TLSA | hexdump -ve '/1 "%02x"')

#
# (0) PKIX-TA: Matches a trusted root or intermediate CA.
# (1) PKIX-EE: Matches a valid certificate by a trusted root CA.
#
# @see https://en.wikipedia.org/wiki/DNS-based_Authentication_of_Named_Entities#Certificate_usage
# @see https://datatracker.ietf.org/doc/html/rfc6698#section-2.1.1
#
if [[ -z "$USAGE" ]]
then
    USAGE="1"
fi

if [[ -z "$DOMAIN" ]]
then
    DOMAIN="use.your.domain"
fi

if [[ -z "$PORT" ]]
then
    PORT="443"
fi

if [[ -z "$PROTOCOL" ]]
then
    PROTOCOL="tcp"
fi

echo "_$PORT._$PROTOCOL.$DOMAIN. IN TLSA $USAGE $SELECTOR $MATCHTYPE $TLSA"
