#!/bin/bash
#
# $ bash dane-tlsa.sh "/path/to/cert.pem"
#
CERTIFICATE="$1"

# Matching type SHA2-256(1) is chosen because all DANE implementations are
# required to support SHA2-256.
USEHASH="SHA256"

if [[ -z "$CERTIFICATE" ]]
then
    >&2 echo "ERROR: No path to certificate defined."
    exit
fi

#
# (2) DANE-TA: Root or intermediate CA (can be self-signed).
# (3) DANE-EE: End certificate (can be self-signed).
#
# @see https://datatracker.ietf.org/doc/html/rfc6698#section-2.1.1
# @see https://datatracker.ietf.org/doc/html/rfc7671#section-4
#
if [[ -z "$USAGE" ]]
then
    USAGE="3"
fi

#
# TLSA Publishers employing DANE-TA(2) records SHOULD publish records with
# a selector of Cert(0). Otherwise selector SPKI(1) is chosen because it
# is compatible with raw public keys [RFC7250] and the resulting TLSA
# record needs no change across certificate renewals with the same key.
#
# (0) Full certificate: the Certificate binary structure as defined in [RFC5280]
# (1) SubjectPublicKeyInfo: DER-encoded binary structure as defined in [RFC5280]
#
# @see https://datatracker.ietf.org/doc/html/rfc6698#section-2.1.2
# @see https://datatracker.ietf.org/doc/html/rfc6698#appendix-A.1.2.2
# @see https://datatracker.ietf.org/doc/html/rfc7671#section-5.2.1 (and 5.1)
#
if [[ "$USAGE" == "2" ]]
then
    SELECTOR="0"
else
    SELECTOR="1"
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
# @see https://datatracker.ietf.org/doc/html/rfc7671#section-5.1
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

###

if [[ -z "$DOMAIN" ]]
then
    DOMAIN="use.your.domain"
fi

if [[ -z "$PORT" ]]
then
    PORT="25"
fi

if [[ -z "$PROTOCOL" ]]
then
    PROTOCOL="tcp"
fi

echo "_$PORT._$PROTOCOL.$DOMAIN. IN TLSA $USAGE $SELECTOR $MATCHTYPE $TLSA"
