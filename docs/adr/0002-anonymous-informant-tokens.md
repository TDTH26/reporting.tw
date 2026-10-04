# 2. Anonymous follow-up with device-generated secrets

**Decision.** Each report returns a case number and a token `<token_id>.<secret>`. The app may generate the
secret itself and store it *before* sending; the server stores only an HMAC (server pepper). Retrying the same
`client_report_id` with the same secret returns the original response, so the offline queue is idempotent.

**Why.** Informants stay anonymous; a network drop between "server committed" and "phone received" must not
lose the token or create a duplicate case.

**Consequences.** Lost phone/reinstall = lost follow-up (stated in the app). Device ids are random per install
and only stored keyed-hashed; networks are hashed per /24 (/48) for soft rate limiting because of carrier NAT.
