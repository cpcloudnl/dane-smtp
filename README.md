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

In summary, you probably want to use the following pattern: DANE-EE(3), SPKI(1), SHA-256(1)
```
_25._tcp.mail.example.com. 300 IN TLSA 3 1 1 <your SHA2-256 hash>
```
Replace the value of ```<your SHA2-256 hash>``` with the value of your own certificate.
<br> Replace ```mail.example.nl``` with your own (sub)domain.
* Multiple mailservers on the _same_ domain need a TLSA record for each of their subdomains.
* Multiple mailservers on a _different_ domain need a TLSA record in each of their zone. With a hash of their own certificate.

The DNS-record consists of the following 4 fields:

### 1. Certificate Usage
* ~~```PKIX-TA(0)```~~
* ~~```PKIX-EE(1)```~~
* ```DANE-TA(2)``` Trust Anchor — Root or Intermediate Certificate
* ```DANE-EE(3)``` End Entity Certificate

> Do [NOT](https://datatracker.ietf.org/doc/html/rfc7672#section-3.1.3) use PKIX-TA(0) and PKIX-EE(1).

> Consider DANE-TA(2) when you are that Root or Intermediate. It makes no sense to use a public authority like Let's Encrypt (X1/R3).

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

### Walkthrough:

#### Finds the mail servers of a domain (MX-records):
```bash
$ dig +short MX "example.com"
```
As an example we state that the command above returns the following result:
```
10 your-mail-server.com.
11 your-backup-mail-server.com.
```
In this case you want to run the openssl commands (explained below) to verify the certificates you receive (for both of these servers).
Then you want to add a TLSA record for each of these servers in their own zone.

#### Opens a TLS connection to a mail server:
```bash
$ openssl s_client -connect "your-mail-server.com:25" -starttls smtp </dev/null
```
> The command above will show you the certificate that is being used.
> When using DANE-TA(2) you need to make sure that you send that Trust Anchor as well. Otherwise there is no value (cfr. certificate) to compare. Therefor verification will never pass.

#### Opens a TLS connection to a mail server (with SNI):
```bash
$ openssl s_client -connect "your-mail-server.com:25" -starttls smtp -servername "mail.example.com" </dev/null
```
> When the certificate is different in the two commands above: Make sure you add a TLSA record for both certificates. Servers that do not support SNI will receive the certificate from the first openssl command (because it is the fallback certificate).

> Prefer using the hostname of the IPv4 (the reverse DNS). In this case all servers (with or without SNI) should receive the same certificate.
> You can verify this by running the two openssl commands above. In this case they must return the same certificate.

#### Generate the [SHA2-256](#3-matching-type) hash based on the [SPKI](#2-selector):
> In the openssl commands above: Most cases will return a single certificate.
> That would be your ```End Entity``` certificate ([DANE-EE](#1-certificate-usage)).
> You want to manually verify that the certificate you received is the same as the one you are using on your server.
```bash
echo $(openssl x509 -in "/path/to/cert.pem" -noout -pubkey \
| openssl pkey -pubin -outform DER \
| openssl sha256 -binary \
| hexdump -ve '/1 "%02x"')
```
In the command above, replace ```/path/to/cert.pem``` with the location of your end certificate.

#### Generate the [SHA2-256](#3-matching-type) hash based on the [Full Certificate](#2-selector):
> DANE-TA(2) [should](https://datatracker.ietf.org/doc/html/rfc7672#section-3.1.2) use the "Full certificate(0)" selector in stead of the "SPKI(1)". Such TLSA records are associated with the whole trust anchor certificate, not just with the trust anchor public key. Otherwise this may, for example, allow a subsidiary CA to issue a chain that violates the trust anchor's path length or name constraints.
```bash
echo $(openssl x509 -in "/path/to/ca.pem" -outform DER \
| openssl sha256 -binary \
| hexdump -ve '/1 "%02x"')
```
In the command above, replace ```/path/to/ca.pem``` with the location of your root or intermediate certificate.

### DNS-record:
DANE-EE(3) with SPKI(1) and SHA256(1) would result in a DNS-record e.g:
```
_25._tcp.your-mail-server.com. IN TLSA 3 1 1 <hash>"
```
And optionally a DNS-record for the backup server:
```
_25._tcp.your-backup-mail-server.com. IN TLSA 3 1 1 <hash>"
```
DANE-TA(2) with FullCert(0) and SHA256(1) would result in a DNS-record e.g:
```
_25._tcp.your-mail-server.com. IN TLSA 2 0 1 <hash>"
```
DANE-TA(2) with Digest Algorithm Agility would result in two DNS-records e.g:
```
_25._tcp.your-mail-server.com. IN TLSA 2 0 1 <sha256-hash>"
_25._tcp.your-mail-server.com. IN TLSA 2 0 2 <sha512-hash>"
```
> Consider the use of Digest Algorithm Agility when SHA2-256 becomes to weak. Until that time you probably just want to use a single record containing the SHA2-256 hash. You always want to implement the 256-bit hash.

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
