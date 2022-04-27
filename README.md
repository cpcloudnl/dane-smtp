# DANE: TLSA DNS-record
## Generates a DNS TLSA-record for DANE
[RFC6698](https://datatracker.ietf.org/doc/html/rfc6698)
/ [RFC7671](https://datatracker.ietf.org/doc/html/rfc7671)
/ [MECSA](https://mecsa.jrc.ec.europa.eu/en/technical#dane)

Bash script to print the suggested TLSA-record.

```bash
$ bash dane-tlsa.sh "/path/to/cert.pem"
```

### Considerations:

#### Use a low TTL
On a certificate renewal, the TLSA record could require an update.

#### Key Rollover with Fixed TLSA Parameters
https://datatracker.ietf.org/doc/html/rfc7671#section-8.1

