#!/bin/bash
#
# $ bash dane-tlsa.sh "/path/to/cert.pem"
#
CERTIFICATE="$1"

if [[ -z "$CERTIFICATE" ]]
then
    >&2 echo "ERROR: No path to certificate defined."
    exit
fi

#
# TLSA records for the port 25 SMTP service used by client MTAs SHOULD NOT
# include TLSA RRs with certificate usage PKIX-TA(0) or PKIX-EE(1). SMTP client
# MTAs cannot be expected to be configured with a complete set of public CAs.
#
# (2) DANE-TA: Root or intermediate CA.
# (3) DANE-EE: End certificate.
#
# @see https://datatracker.ietf.org/doc/html/rfc6698#section-2.1.1
# @see https://datatracker.ietf.org/doc/html/rfc7671#section-4 (and 12)
# @see https://datatracker.ietf.org/doc/html/rfc7672#section-3.1.2
#
if [[ -z "$USAGE" ]]
then
    # SMTP servers that rely on certificate usage DANE-TA(2) TLSA records
    # for TLS authentication MUST include the TA certificate as part of the
    # certificate chain presented in the TLS handshake server certificate
    # message even when it is a self-signed root certificate.
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
# (1) SHA256 hash of selected content: SHA-256 [RFC 6234]
# (2) SHA512 hash of selected content: SHA-512 [RFC 6234]
#
# @see https://datatracker.ietf.org/doc/html/rfc6698#section-2.1.3
# @see https://datatracker.ietf.org/doc/html/rfc7671#section-5.1 (and 10.1.2)
#
# Matching type SHA2-256(1) is chosen because all DANE implementations are
# required to support SHA2-256. Not using a hash is NOT RECOMMENDED.
#
DIGEST="-sha256"
#
# When SHA256 becomes to weak, both SHA256 and SHA512 can be used.
# Until that time it seems better to only use SHA256 because a client
# does not necessarily implement the agility as expected. It also does
# not add any additional security as long as SHA256 is not a weak hash.
# The agility, in future uses, will use the strongest supported algo
# when the set of records contains two records for both the algorithms.
#
# @see https://datatracker.ietf.org/doc/html/rfc7671#section-9
# @see https://crypto.stackexchange.com/a/52572
#
if [[ "$DIGEST" == "-sha512" ]]
then
    MATCHTYPE="2"
else
    MATCHTYPE="1"
fi

#
# openssl
#
if [[ -f "$CERTIFICATE" ]]
then
    TLSA="openssl x509 -in \"$CERTIFICATE\""
else
    TLSA="echo \"\$CERTIFICATE\" | openssl x509"
fi

if [[ "$SELECTOR" == "1" ]]
then
    TLSA="$TLSA -noout -pubkey | openssl pkey -pubin"
fi

TLSA="$TLSA -outform DER | openssl dgst $DIGEST -binary"
TLSA=$(eval $TLSA | hexdump -ve '/1 "%02x"')
TLSA=$(echo "$TLSA" | tr '[:lower:]' '[:upper:]')

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

echo "_$PORT._$PROTOCOL.$DOMAIN. 300 IN TLSA $USAGE $SELECTOR $MATCHTYPE $TLSA"
