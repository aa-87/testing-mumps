CRYPTO ; MUMPS.IO - Password hashing interface (Argon2id preferred)
  QUIT
  ;
  ; Public:
  ;   $$HASH^CRYPTO(plain,.phc)   -> 1 on success, phc = $argon2id$...
  ;   $$VERIFY^CRYPTO(plain,phc)  -> 1 if match, 0 otherwise
  ;
  ; Implementation delegates to EXTCRYPTO (argon2 CLI) by default.
  ;
HASH(pwd,phc) NEW ok S phc="",ok=0
  ; Argon2id parameters (safe defaults)
  NEW iter,mem,par,hlen S iter=3,mem=16,par=1,hlen=32
  ; mem is log2 KiB (argon2 CLI -m), 16 => 65536 KiB (64 MiB)
  S ok=$$ARGON2HASH^EXTCRYPTO(pwd,.phc,iter,mem,par,hlen)
  Q ok

VERIFY(pwd,phc) Q $$ARGON2VERIFY^EXTCRYPTO(pwd,phc)
