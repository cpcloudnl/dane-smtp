# DANE TLS: DNS-Based Authentication

Use DANE to start and verify secure SMTP connections between MTAs. This mitigates an MITM-attack.

[RFC6698](https://datatracker.ietf.org/doc/html/rfc6698)
/ [RFC7671](https://datatracker.ietf.org/doc/html/rfc7671)
/ [RFC7672](https://datatracker.ietf.org/doc/html/rfc7672)

### Prerequisites

#### Inbound email:
* Your mail server has support for STARTTLS.
* Your domain (and mail server domain) are using DNSSEC.

👉 DANE for inbound email means [publishing a DNS record](#tlsa-resource-record).

#### Outbound email:
* Your mail server has support for DANE.

👉 DANE for outbound email means [configuring your mailserver](#configuring-mail-server).

### How DANE works:
DANE initiates a TLS connection. A server that wants to send you an email receives the certificate from your mailserver.
DANE verifies that certificate by searching for a match in the set of TLSA-records (in the DNS). One of those records must match in order to succeed.

The domain in the MX-record is used to connect with TLS on TCP port 25.

## TLSA Resource Record 

With a TLSA record in your DNS; A sending server can verify the certificate that it receives.
<br> The DNS-record consists of the following 4 fields:

### 1. Certificate Usage
* ~~```PKIX-TA(0)```~~
* ~~```PKIX-EE(1)```~~
* ```DANE-TA(2)``` Intermediate Certificate
* ```DANE-EE(3)``` End Entity Certificate

> Do [NOT](https://datatracker.ietf.org/doc/html/rfc7672#section-3.1.3) use PKIX-TA(0) and PKIX-EE(1).

### 2. Selector
* ```Cert(0)``` Full Certificate
* ```SPKI(1)``` Subject Public Key Info

> TLSA Publishers employing DANE-TA(2) records SHOULD publish records with
  a selector of "Cert(0)". Otherwise SPKI(1) is recommended because it
  is compatible with raw public keys [RFC7250] and the resulting TLSA
  record needs no change across certificate renewals with the same key.

### 3. Matching Type
* ~~```Full(0)```~~
* ```SHA-256(1)``` SHA2-256 hash
* ```SHA-512(2)``` SHA2-512 hash

> Always use SHA-256(1). It is the only one required. ~~Optionally use both hashes with [Digest Algorithm Agility](https://datatracker.ietf.org/doc/html/rfc7672#section-5)~~. Do [NOT](https://datatracker.ietf.org/doc/html/rfc7671#section-10.1.2) use type Full(0).

### 4. Certificate Association Data

> Contains the hashed value of the Certificate or Public Key.

## Walkthrough

#### Find the MX-records:
```bash
$ bash ...
```

...

## Configuring mail server

Email that you send, will search for the TLSA records of the receivers MX-domain. When a record is found, your server will start a TLS connection and verify the certificate it receives.

* [Configuring Postfix mailserver](https://github.com/your-host/toolbox-wiki/blob/patch-1/DANE-for-SMTP-how-to-Postfix.md)
* [Configuring Exim mailserver](https://github.com/your-host/toolbox-wiki/blob/patch-1/DANE-for-SMTP-how-to-Exim.md)

<hr />
<hr />

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
