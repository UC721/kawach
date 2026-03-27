# KAWACH Security Policy

> **Your Shield. Always.** — Every layer of KAWACH is designed to protect user
> safety data at rest, in transit, and during peer-to-peer relay.

---

## Security Architecture Summary

| Layer | Mechanism | Details |
|---|---|---|
| **Transport (cloud)** | TLS 1.3 + certificate pinning | All Supabase API calls use a pinned HTTP client (`lib/core/security/certificate_pinning.dart`) that rejects connections whose certificate fingerprints are not in the allow-list. |
| **Evidence at rest** | ChaCha20-Poly1305, key in Supabase Vault | Evidence files are encrypted client-side before upload. Per-evidence keys are derived via HKDF-SHA256 from a master key stored in Supabase Vault. See `lib/core/security/encryption_service.dart`. |
| **Mesh messages** | X25519 ECDH + ChaCha20-Poly1305 per hop | Each relay hop negotiates an ephemeral X25519 shared secret. Payloads are encrypted with ChaCha20-Poly1305. See `lib/services/mesh/mesh_crypto_service.dart`. |
| **Message integrity** | Ed25519 signatures | Every mesh message and evidence item is signed with the sender's Ed25519 key. Receivers verify signatures before processing. |
| **User identity** | Phone OTP + JWT (15 min expiry) | Users authenticate via SMS OTP through Supabase Auth. JWTs expire after 15 minutes and are auto-refreshed. See `lib/services/auth_service.dart`. |
| **Guardian access to evidence** | Signed 15-min URLs, audit logged | Guardians access evidence exclusively through the `sign-evidence-url` edge function, which generates time-limited signed URLs and logs every access. |
| **Device keys** | Android Keystore / iOS Secure Enclave | The master encryption key and Ed25519 signing key are stored in platform-secure storage via `FlutterSecureStorage` (Android Keystore / iOS Keychain backed by Secure Enclave). See `lib/core/security/key_manager.dart`. |
| **RLS (database)** | Every table enforces `auth.uid()` policies | All Supabase tables have Row-Level Security enabled. Policies ensure users can only access their own data (or data shared via confirmed guardian relationships). See `supabase/migrations/20260315000001_create_tables.sql`. |
| **Rate limiting** | SOS: max 3 in 10 min per user | The `sos` edge function enforces a sliding-window rate limit of 3 SOS alerts per 10-minute window per user. See `supabase/functions/sos/index.ts`. |
| **Guardian verification** | OTP confirmation + 48h cooldown to remove | Guardians must confirm their role via OTP. A 48-hour cooldown period is enforced before a confirmed guardian can be removed. See `supabase/functions/guardians-verify/index.ts`. |
| **Spam prevention** | AI fraud score on SOS + velocity check | Each SOS alert receives a fraud score (0.0–1.0) based on velocity checks, location plausibility, and time-of-day heuristics. Alerts scoring ≥ 0.7 are flagged for review. See `lib/services/fraud_detection_service.dart`. |
| **Anonymized location** | Only geohash-5 (~5 km²) exposed to CrowdShield peers | Precise GPS coordinates are never shared with crowd peers. Only a geohash-5 cell (~4.9 km × 4.9 km) is transmitted via `crowd_alerts`. See `lib/services/location_anonymizer.dart`. |

---

## Key Files

| File | Purpose |
|---|---|
| `lib/core/security/encryption_service.dart` | ChaCha20-Poly1305 encryption, X25519 ECDH, Ed25519 signing |
| `lib/core/security/key_manager.dart` | Master key, evidence key derivation, signing key management |
| `lib/core/security/certificate_pinning.dart` | TLS certificate pinning HTTP client |
| `lib/services/mesh/mesh_crypto_service.dart` | Per-hop mesh message encryption |
| `lib/services/auth_service.dart` | Phone OTP + JWT authentication |
| `lib/services/fraud_detection_service.dart` | SOS fraud scoring + velocity checks |
| `lib/services/location_anonymizer.dart` | Geohash-5 location anonymization |
| `supabase/migrations/20260315000001_create_tables.sql` | Table definitions + RLS policies |
| `supabase/functions/sos/index.ts` | Rate-limited SOS endpoint |
| `supabase/functions/sign-evidence-url/index.ts` | Signed evidence URL generation |
| `supabase/functions/guardians-verify/index.ts` | Guardian OTP verification + 48h cooldown |

---

## Reporting Vulnerabilities

If you discover a security vulnerability in KAWACH, please report it
responsibly by emailing the maintainers. Do **not** open a public issue for
security vulnerabilities.
