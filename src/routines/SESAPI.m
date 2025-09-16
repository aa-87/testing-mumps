SESAPI ; MUMPS.IO - Session management (opaque tokens, server-stored)
  QUIT
  ;
  ; ^SESS(token,"uid")=uid
  ; ^SESS(token,"exp")=ISO8601
  ; ^SESS(token,"created_at")=ISO8601
  ; ^SESSID(uid,token)=""
  ; ^SESS("ttl")=seconds (default 14400 = 4h)
  ;
CREATE(uid) NEW ttl,tok,now,exp
  I +$G(uid)'>0 Q ""
  S ttl=+$G(^SESS("ttl"),14400)
  ; generate 32B random base64url token
  S tok=$$RANDTOKEN(32) I tok="" Q ""
  ; store
  S now=$$NOW(),exp=$$ADDSEC(now,ttl)
  S ^SESS(tok,"uid")=uid,^SESS(tok,"created_at")=now,^SESS(tok,"exp")=exp
  S ^SESSID(uid,tok)=""
  Q tok
CHECK(tok) NEW exp,uid
  S tok=$G(tok) I tok="" Q 0
  S exp=$G(^SESS(tok,"exp")) I exp="",'$D(^SESS(tok)) Q 0
  I $$CMPISO(exp,$$NOW())=-1 D REVOKE(tok) Q 0
  S uid=+$G(^SESS(tok,"uid")) Q uid
REVOKE(tok)
  N uid S uid=+$G(^SESS(tok,"uid"))
  K ^SESS(tok) I uid>0 K ^SESSID(uid,tok)
  Q
PURGE ; remove expired tokens
  N tok S tok=""
  F  S tok=$O(^SESS(tok)) Q:tok=""  D
  . I tok="ttl" Q
  . N exp S exp=$G(^SESS(tok,"exp")) I exp'="",$$CMPISO(exp,$$NOW())=-1 D REVOKE(tok)
  Q
; ------------- utils -------------
RANDTOKEN(n) NEW b64
  ; Try external strong randomness (Linux)
  NEW cmd S cmd="openssl rand -base64 "_+$G(n,32)
  S b64=$$RUN(cmd)
  I b64="" Q ""
  ; base64url: +/ -> -_, drop =
  S b64=$TR($P(b64,$C(10),1),"+/","-_")
  F  Q:$E(b64,$L(b64))'="="  S b64=$E(b64,1,$L(b64)-1)
  Q b64

RUN(cmd) NEW tmp,out,sts
  S tmp="/tmp/mio-"_$J_"-"_$R(1000000)_".out"
  ZSYSTEM cmd_" >"_tmp_" 2>/dev/null" S out=$$READFILE(tmp),sts=$ZPOS
  O tmp:(readonly):0 I '$T  Q out
  C tmp ;K ^|| ; just ensure closed
  Q out

READFILE(p) NEW x,io S x="",io=p
  O io:(readonly):0 I '$T  Q ""
  U io R x#1048576 C io
  Q x
NOW() Q $zd($zh,"YYYY-MM-DD")_"T"_$zd($zh,"24:60:SS")_"Z"
; add seconds to ISO8601 (coarse; relies on $ZDATETIME/$ZDATETIMEH)
ADDSEC(iso,sec) ;NEW h S h=$ZDATETIMEH($TR(iso,"T"," "),3) Q $TR($ZDATETIME(h+sec,3)," ","T")_"Z"
	N H S H=$$ISOTOH(iso) N XD
	S $P(H,",",2)=$P(H,",",2)+sec
	S XD=$P(H,",",2)\86399,$P(H,",",2)=$P(H,",",2)#86399
	S $P(H,",")=$P(H,",")+XD
	Q $$HTOISO(H)
; compare two ISO strings (YYYY-MM-DDTHH:MM:SSZ)
CMPISO(A,B) Q $S($G(A)=$G(B):0,$G(A)']$G(B):-1,1:1)
;CONVERT ISO TO MUMPS $H
; $$FUNC^%DATE("02/08/2018")
; $$FUNC^%TI("10:09")
; 2025-09-15T20:22:18Z
ISOTOH(DT)
	N YYYY,MM,DD,HH,MINS,SS,AMPM,XD S AMPM="AM"
	S YYYY=$P(DT,"-")
	S MM=$P(DT,"-",2)
	S DD=$P($P(DT,"-",3),"T")
	S HH=$P($P($P(DT,"-",3),"T",2),":")
	S MINS=$P($P($P(DT,"-",3),"T",2),":",2)
	S SS=$P($P($P($P(DT,"-",3),"T",2),":",3),"Z")
	I HH>12 S HH=HH-12,AMPM="PM"
	N H,T S H=$$FUNC^%DATE(MM_"/"_DD_"/"_YYYY)
	S T=$$FUNC^%TI(HH_":"_MINS_AMPM)
	S T=T+SS S XD=T\86399,T=T#86399
	Q (H+XD)_","_T
	;
HTOISO(H) Q $zd(H,"YYYY-MM-DD")_"T"_$zd(H,"24:60:SS")_"Z"