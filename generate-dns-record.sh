#!/bin/bash

#
# Common use-case for generating a DANE TLSA DNS record.
#
# $ bash ./generate-dns-record.sh "server.your-domain.com"
#

#
# Verify STARTTLS is supported on the mail server:
#
# 1. Run in terminal:
#
# $ openssl s_client -connect server.your-domain.com:25 -starttls smtp
#
# 2. Then type:
# STARTTLS
#
# 3. Press the Enter-key
# 4. Inspect the response.
#
# Example of a valid response: 554 Already in TLS
#

MAIL_DOMAIN="${1}"
CERTIFICATE=$(echo -n | openssl s_client -connect "${MAIL_DOMAIN}:25" -starttls smtp 2>/dev/null)
TLSA_RECORD=$(echo "${CERTIFICATE}" | openssl x509 -noout -pubkey \
| openssl pkey -pubin -outform DER \
| openssl sha256 -binary \
| hexdump -ve '/1 "%02x"')

echo ""
echo "#"
echo "# The Certificate that the server returned:"
echo "# > You MUST verify these contents before publishing the DNS record!"
echo "# > Verify this by comparing these contents with the file on your server"
echo "# > or the e-mail you received with your certificate."
echo "# > The Common Name should match the given e-mail domain for the EE."
echo "# > The certificate issuer MUST match the expected issuer."
echo "# > Ensure the certificate NotBefore/NotAfter is within the current time."
echo "#"
echo "${CERTIFICATE}"
echo ""
echo "#"
echo "# The DANE TLSA DNS record for the certificate above:"
echo "#"
echo "_25._tcp.${MAIL_DOMAIN}. 300 IN TLSA 3 1 1 ${TLSA_RECORD}"
echo ""
echo "#"
echo "# -----------------------------"
echo "# In your Cloudflare dashboard:"
echo "# -----------------------------"
echo "# >          Type: TLSA"
echo "# >          Name: _25._tcp.${MAIL_DOMAIN}."
echo "# >           TTL: 5 min"
echo "# >         Usage: 3"
echo "# >      Selector: 1"
echo "# > Matching type: 1"
echo "# >   Certificate: ${TLSA_RECORD}"
echo "#"
echo "#"
echo "# !!! NOTE: Keep the previous TLSA-record. Add a new DNS record."
echo "#           Always keep the record of the previous AND the current Cert."
echo "#           Older records can be removed."
echo "#           In Cloudflare dashboard: Add a comment with the issue date."
echo "#"
echo "# > Do not forget to set this up for each of the MX-domains."
echo "# > Ensure the Cert of the MX-domain is the same with or without SNI."
echo "# > Add the new DNS-record BEFORE installing the new Cert on the server."
echo "#"
