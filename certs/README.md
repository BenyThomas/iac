# TLS Certificates

This directory stores TLS certificates for tcbbank.co.tz. All subdomains are expected to use the certificate bundle stored under `tls/`:

- `tls/tcb.crt` – Certificate for tcbbank.co.tz covering subdomains.
- `tls/fullchain.crt` – Full certificate chain.
- `tls/tcb.key` – Private key associated with the certificate.
- `tls/DigiCertCA.crt` – Certificate authority chain file.

Keep these files up to date and replace them when renewing the certificate. Ensure appropriate access controls are applied when handling the private key.
