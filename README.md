# DANE TLS: DNS-Based Authentication of Named Entities

Use DANE to secure SMTP connections between MTAs.

[RFC6698](https://datatracker.ietf.org/doc/html/rfc6698)
/ [RFC7671](https://datatracker.ietf.org/doc/html/rfc7671)
/ [RFC7672](https://datatracker.ietf.org/doc/html/rfc7672)

DANE validates a secure connection. A secure connection to a mail server sends a certificate.
DANE verifies that certificate by searching for a match in the DNS records. The TLSA-records are a set of records. One of the records must match the sent certificate in order to succeed.

The domain found in the DNS MX-record is used to connect with STARTTLS on TCP port 25.

## TLSA Resource Record 

With a TLSA record in your DNS; A sending server can verify the certificate that it receives.
<br> The record consists of the following fields:

### Certificate Usage
* ~~```PKIX-TA(0)```~~
* ~~```PKIX-EE(1)```~~
* ```DANE-TA(2)``` Intermediate Certificate (when you are an email [SaaS-provider](#use-dane-ta-if-you-are-a-saas-provider))
* ```DANE-EE(3)``` End Entity Certificate (also called host or server certificate)

> Do [NOT](https://datatracker.ietf.org/doc/html/rfc7672#section-3.1.3) use PKIX-TA(0) and PKIX-EE(1).

### Selector
* ```Cert(0)``` Full Certificate
* ```SPKI(1)``` Subject Public Key Info

> TLSA Publishers employing DANE-TA(2) records SHOULD publish records with
  a selector of "Cert(0)". Otherwise SPKI(1) is recommended because it
  is compatible with raw public keys [RFC7250] and the resulting TLSA
  record needs no change across certificate renewals with the same key.

### Matching Type
* ~~```Full(0)```~~
* ```SHA-256(1)``` SHA2-256 hash (always use this)
* ```SHA-512(2)``` SHA2-512 hash (only add if required, then use both with [Digest Algorithm Agility](https://datatracker.ietf.org/doc/html/rfc7672#section-5))

> Do [NOT](https://datatracker.ietf.org/doc/html/rfc7671#section-10.1.2) use matching type of Full(0).

### Certificate Association Data

> Hashed value of the Certificate or Public Key.

## Walkthrough

#### Find the MX-records:
```bash
$ bash ...
```

...

## Configure your mail server

Email that you send, will search for the TLSA records of the receivers MX-domain. When a record is found, your server will start a TLS connection and verify the certificate it receives.

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

#### Key Rollover with Fixed TLSA Parameters:
https://datatracker.ietf.org/doc/html/rfc7671#section-8.1
