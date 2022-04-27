# SMTP Security via DANE: TLSA DNS-record

#### Finds the mail server for a domain and validates the record:

```bash
$ bash validate-dane-tlsa.sh "example.com"
```

#### Prints the suggested TLSA-record:

```bash
$ bash dane-tlsa.sh "/path/to/cert.pem"
```

<hr />

[RFC6698](https://datatracker.ietf.org/doc/html/rfc6698)
/ [RFC7671](https://datatracker.ietf.org/doc/html/rfc7671)
/ [RFC7672](https://datatracker.ietf.org/doc/html/rfc7672)
/ [MECSA](https://mecsa.jrc.ec.europa.eu/en/technical#dane)

#### Key Rollover with Fixed TLSA Parameters:
https://datatracker.ietf.org/doc/html/rfc7671#section-8.1
