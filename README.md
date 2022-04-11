# DANE: TLSA DNS-record
## Generates a DNS TLSA-record for DANE / [RFC6698](https://datatracker.ietf.org/doc/html/rfc6698)

Bash script to print the suggested TLSA-record.

> ⚠️ The script fetches the certificate. The certificate MUST be manually verified.
> <br>! A better solution is to get the certificate from the server.
> <br>! @TODO: Provide option to define certificate path.
> <br>! @TODO: Provide option to fetch certificate through API (Cloudflare/cPanel).

### Quick start:

> ! The script will create the directories: "$HOME/tmp/certs-dane-tlsa".
> <br>! The script will NOT cleanup the contents of that directory
  nor the upper directory or directories that it created.

```bash
$ /bin/bash dane-tlsa-443.sh "use.your.domain" full auto
```

### Syntax:

```bash
dane-tlsa-443.sh "use.your.domain" [ full|pubk [ auto|SHA256|SHA512 ] ]
```

The first parameter defines the selector. Either uses the full certificate or the public key.
<br>The full certificate is used by default (most secure).

The second parameter defines the hashing algorithm.
<br>When undefined, no hashing is done (exact match).
<br>'auto' tries to match the certs hash when 'SHA512'. Otherwise 'SHA256' is used.

<hr />

### Considerations:

<hr />

#### Use 'full' unless you have considered: [rfc6698#appendix-A.1.2.2](https://datatracker.ietf.org/doc/html/rfc6698#appendix-A.1.2.2)
> ... Unless the full implications of such an association are
> understood by the administrator, using selector type 0 is a better
> option from a security perspective.

<hr />

#### Use hashing for the 'full' certificate. Without, the value can be too long.
Hashes can potentially have collision.
<br>In the case of 'pubk': Not hashing can be considered.

<hr />

#### Use 'auto' or specify the same signature algorithm of your certificate: [rfc6698#section-2.1.3](https://datatracker.ietf.org/doc/html/rfc6698#section-2.1.3)
> If the TLSA record's matching type is a hash, having the record use
> the same hash algorithm that was used in the signature in the
> certificate (if possible) will assist clients that support a small
> number of hash algorithms.

<hr />

#### Use a low TTL to mitigate downtime when your certificate expires.
On a certificate renewal, the TLSA record must be updated.

<hr />
