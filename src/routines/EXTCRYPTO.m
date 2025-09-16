EXTCRYPTO ; MUMPS.IO - External crypto via argon2 CLI (Linux sample)
  QUIT
  ; Requires the argon2 CLI and openssl (for salt). On most Linux distros: apt/yum install argon2 openssl.
  ;
  ; $$ARGON2HASH^EXTCRYPTO(pwd,.phc,iter,mem,par,hlen) -> 1/0
  ; $$ARGON2VERIFY^EXTCRYPTO(pwd,phc)                  -> 1/0
  ;
ARGON2HASH(pwd,phc,iter,mem,par,hlen) NEW salt,cmd,out
  S phc="" S salt=$$GENSALT()
  I salt="" Q 0
  ; Build shell line: echo -n 'pwd' | argon2 <salt> -id -t iter -m mem -p par -l hlen -e
  NEW qpwd S qpwd=$$SHESC(pwd)
  S cmd="sh -c ""printf %s "_qpwd_" | argon2 "_salt_" -id -t "_+iter_" -m "_+mem_" -p "_+par_" -l "_+hlen_" -e"""
  S out=$$RUN(cmd) I out="" Q 0
  ; first line is PHC: $argon2id$v=19$m=65536,t=3,p=1$<salt>$<hash>
  S phc=$P(out,$C(10),1)
  I $E(phc,1,9)'="$argon2id" Q 0
  Q 1

ARGON2VERIFY(pwd,phc) NEW prm,salt,iter,mem,par,hlen,enc,cmd,out
  I phc="" Q 0
  ; parse PHC
  S prm=$P(phc,"$",4),salt=$P(phc,"$",5)
  I prm=""!(salt="") Q 0
  S mem=$$GETP(prm,"m"),iter=$$GETP(prm,"t"),par=$$GETP(prm,"p")
  I mem=""!(iter="")!(par="") Q 0
  ; derive hash with same params
  NEW qpwd S qpwd=$$SHESC(pwd)
  ; We don't need hash length explicitly; argon2 -e emits full PHC with same params
  S cmd="sh -c ""printf %s "_qpwd_" | argon2 "_salt_" -id -t "_+iter_" -m "_+mem_" -p "_+par_" -e"""
  S out=$$RUN(cmd) I out="" Q 0
  S enc=$P(out,$C(10),1)
  Q $S(enc=phc:1,1:0)

; --- helpers ---
GENSALT() NEW s S s=$$RUN("openssl rand -base64 16") S s=$P(s,$C(10),1) Q $$B64URL(s)
B64URL(x) NEW y S y=$TR(x,"+/","-_") F  Q:$E(y,$L(y))'="="  S y=$E(y,1,$L(y)-1) Q:y
  Q y
GETP(pr,k) NEW v S v=$P($P(pr,k_"=",2),",",1) Q v
RUN(cmd) NEW tmp,out S tmp="/tmp/mio-crypto-"_$J_"-"_$R(1000000)_".out"
  ZSYSTEM cmd_" >"_tmp_" 2>/dev/null"
  O tmp:(readonly):0 i '$t  Q ""
  U tmp N x R x#1048576 C tmp S out=x
  Q out
SHESC(s) ; shell-safe single argument for printf %s
  NEW r S r="'"_$TR($G(s),"'","'\\''")_"'"
  Q r
