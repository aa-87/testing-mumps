AUTHAPI ; MUMPS.IO - Auth + Users API (server-side hashing, opaque sessions)
  QUIT
  ;
  ; Globals (users):
  ;   ^USR(id,"email") ^USR(id,"password_hash") ^USR(id,"role") ^USR(id,"active")
  ;   ^USR(id,"email_verified") ^USR(id,"email_verified_at") ^USR(id,"created_at") ^USR(id,"updated_at")
  ;   ^USRIDX("email",lower)=id  ^USR("last")
  ;
  ; Globals (sessions) in SESAPI: ^SESS(token,...)  ^SESSID(uid,token)=""
  ;
  ; Router endpoints:
  ;   POST /api/auth/signup   -> SIGNUP^AUTHAPI   IN(email,password)          OUT(user,token)
  ;   POST /api/auth/signin   -> SIGNIN^AUTHAPI   IN(email,password)          OUT(user,token)
  ;   POST /api/auth/signout  -> SIGNOUT^AUTHAPI  IN(token?) or Authorization OUT(ok)
  ;
  ;   (Existing Users/Admin)
  ;   POST /api/users/create  -> CREATE^AUTHAPI   IN(email,password_hash) OUT(user)
  ;   POST /api/users/get     -> GET^AUTHAPI      IN(id,with_hash?)       OUT(user)
  ;   POST /api/users/by-email-> BYEMAIL^AUTHAPI  IN(email)               OUT(user WITH password_hash)  [INTERNAL]
  ;   POST /api/users/update  -> UPDATE^AUTHAPI   IN(id,patch...)          OUT(ok)
  ;   POST /api/users/search  -> SEARCH^AUTHAPI   IN(search,page,limit)    OUT(total,items[])
  ;   POST /api/admin/stats   -> STATS^AUTHAPI                               OUT(agg)
  ;
  ; Helpers:
  ;   GETTOKEN^AUTHAPI(IN)        -> token from header IN("%HDR","Authorization") or IN("token")
  ;   REQUIREAUTH^AUTHAPI(IN,.UID)-> 200 & UID set; otherwise OUT("%HTTP")=401
  ;   REQUIREADMIN^AUTHAPI(IN)    -> 403 if not admin
  ;
  ; NOTE: JSON encode/decode handled by web gateway. We only fill OUT(...).

; =========================
; AUTH flows (server-side)
; =========================
SIGNUP(IN,OUT) NEW email,pwd,hash,id,user,now
  K OUT S email=$$LOW($G(IN("email"))),pwd=$G(IN("password"))
  I email=""!(pwd="") D SETHTTP(.OUT,400,"invalid") Q
  ; hash server-side (Argon2id preferred)
  NEW ok,phc S ok=$$HASH^CRYPTO(pwd,.phc) I 'ok D SETHTTP(.OUT,500,"crypto_unavailable") Q
  ; create user (re-using CREATE logic under lock)
  NEW tmp S tmp("email")=email,tmp("password_hash")=phc
  D CREATE(.tmp,.OUT) I $G(OUT("%HTTP")) Q  ; propagate error (409 email_taken etc.)
  ; issue session token
  NEW token S token=$$CREATE^SESAPI(OUT("id"))
  I token="" D SETHTTP(.OUT,500,"session_failed") Q
  ; include token in response
  S OUT("token")=token
  Q

SIGNIN(IN,OUT) NEW email,pwd,id,phc,u,ok
  K OUT S email=$$LOW($G(IN("email"))),pwd=$G(IN("password"))
  I email=""!(pwd="") D SETHTTP(.OUT,400,"invalid") Q
  S id=$G(^USRIDX("email",email)) I 'id D SETHTTP(.OUT,401,"invalid_creds") Q
  I '$D(^USR(id)) D SETHTTP(.OUT,401,"invalid_creds") Q
  I '+$G(^USR(id,"active")) D SETHTTP(.OUT,401,"invalid_creds") Q
  S phc=$G(^USR(id,"password_hash")) I phc="" D SETHTTP(.OUT,401,"invalid_creds") Q
  S ok=$$VERIFY^CRYPTO(pwd,phc) I 'ok D SETHTTP(.OUT,401,"invalid_creds") Q
  ; build user object
  D OUTREC(.OUT,id,0)
  ; session token
  NEW token S token=$$CREATE^SESAPI(id) I token="" D SETHTTP(.OUT,500,"session_failed") Q
  S OUT("token")=token
  Q

SIGNOUT(IN,OUT) NEW tok
  K OUT S tok=$$GETTOKEN(.IN)
  I tok'="" D REVOKE^SESAPI(tok)
  S OUT("ok")=1
  Q

; =========================
; Existing Users (with server-side hashing kept internal)
; =========================
CREATE(IN,OUT) NEW email,hash,now,id,lower S (email,hash)="" K OUT
  S email=$G(IN("email")),hash=$G(IN("password_hash"))
  I email=""!(hash="") D SETHTTP(.OUT,400,"invalid") Q
  N eLower S eLower=$$LOW(email)
  L +^USRIDX("email",eLower):3 E  D SETHTTP(.OUT,503,"busy") Q
  I $D(^USRIDX("email",eLower)) D  L -^USRIDX("email",eLower) Q
  . D SETHTTP(.OUT,409,"email_taken")
  L +^USR("last"):3 E  D SETHTTP(.OUT,503,"busy") L -^USRIDX("email",eLower) Q
  S id=$G(^USR("last"),0)+1,^USR("last")=id L -^USR("last")
  S now=$$NOW()
  S ^USR(id,"id")=id,^USR(id,"email")=eLower,^USR(id,"password_hash")=hash
  S ^USR(id,"role")="user",^USR(id,"active")=1,^USR(id,"email_verified")=0
  S ^USR(id,"email_verified_at")="",^USR(id,"created_at")=now,^USR(id,"updated_at")=now
  S ^USRIDX("email",eLower)=id L -^USRIDX("email",eLower)
  D OUTREC(.OUT,id,0)
  Q

GET(IN,OUT) NEW id,withHash S id=+$G(IN("id")),withHash=+$G(IN("with_hash")) K OUT
  I 'id D SETHTTP(.OUT,400,"invalid") Q
  I '$D(^USR(id)) D SETHTTP(.OUT,404,"not_found") Q
  D OUTREC(.OUT,id,withHash)
  Q

BYEMAIL(IN,OUT) NEW email,id S email=$$LOW($G(IN("email"))) K OUT
  I email="" D SETHTTP(.OUT,400,"invalid") Q
  S id=$G(^USRIDX("email",email)) I 'id D SETHTTP(.OUT,404,"not_found") Q
  D OUTREC(.OUT,id,1) ; include hash (INTERNAL — avoid exposing over public routes)
  Q

UPDATE(IN,OUT) NEW id S id=+$G(IN("id")) K OUT
  I 'id D SETHTTP(.OUT,400,"invalid") Q
  I '$D(^USR(id)) D SETHTTP(.OUT,404,"not_found") Q
  N p S p=$NA(IN("patch")) N now S now=$$NOW()
  ; email change with uniqueness
  I $D(@p@("email")) D  I $G(OUT("%HTTP")) Q
  . N newE S newE=$$LOW($G(@p@("email"))) I newE="" D SETHTTP(.OUT,400,"invalid") Q
  . I newE'=$G(^USR(id,"email")) D
  . . L +^USRIDX("email",newE):3 E  D SETHTTP(.OUT,503,"busy") Q
  . . I $D(^USRIDX("email",newE)) D  L -^USRIDX("email",newE) Q
  . . . D SETHTTP(.OUT,409,"email_taken")
  . . N oldE S oldE=$G(^USR(id,"email")) I oldE'="" K ^USRIDX("email",oldE)
  . . S ^USR(id,"email")=newE,^USRIDX("email",newE)=id L -^USRIDX("email",newE)
  ; other allowed fields
  I $D(@p@("role")) S ^USR(id,"role")=$G(@p@("role"))
  I $D(@p@("active")) S ^USR(id,"active")=+$G(@p@("active"))
  I $D(@p@("email_verified")) S ^USR(id,"email_verified")=+$G(@p@("email_verified"))
  I $D(@p@("email_verified_at")) S ^USR(id,"email_verified_at")=$G(@p@("email_verified_at"))
  I $D(@p@("password_hash")) S ^USR(id,"password_hash")=$G(@p@("password_hash"))
  S ^USR(id,"updated_at")=$S($D(@p@("updated_at")):$G(@p@("updated_at")),1:now)
  S OUT("ok")=1 Q

SEARCH(IN,OUT) NEW q,page,limit,off,total S (q,page,limit)="" K OUT
  S q=$$LOW($G(IN("search"))) S page=$$NUM($G(IN("page")),1) S limit=$$NUM($G(IN("limit")),20) I limit<1 S limit=1 I limit>100 S limit=100
  N TMP S TMP=$NA(^TMP($J,"AUTHAPI","S")) K @TMP
  N e,id I q'="" D  E  D
  . S e="" F  S e=$O(^USRIDX("email",e)) Q:e=""  I e[q S id=$G(^USRIDX("email",e)) I id>0 S @TMP@(id)=""
  . ; else include all
  . S id=0 F  S id=$O(^USR(id)) Q:'id  S @TMP@(id)=""
  ; count & page in DESC id
  S total=0,id=0 F  S id=$O(@TMP@(id)) Q:'id  S total=total+1
  S OUT("total")=total
  N idx,emit,cur,skip S emit=0,skip=(page-1)*limit,cur=$O(@TMP@(""),-1)
  F  Q:(cur="")!(emit'<limit)  D
  . I skip>0 S skip=skip-1 G NXT
  . S idx=emit+1,emit=emit+1 D OUTITEM(.OUT,idx,cur)
NXT  . S cur=$O(@TMP@(cur),-1)
  K @TMP Q

STATS(IN,OUT) K OUT N id,tot,ver,act,adm S (tot,ver,act,adm)=0
  S id=0 F  S id=$O(^USR(id)) Q:'id  D
  . S tot=tot+1 S:$G(^USR(id,"email_verified")) ver=ver+1 S:$G(^USR(id,"active")) act=act+1 S:$G(^USR(id,"role"))="admin" adm=adm+1
  S OUT("total")=tot,OUT("verified")=ver,OUT("active")=act,OUT("admins")=adm Q

; =========================
; Helpers
; =========================
OUTREC(OUT,id,withHash) NEW b S b=$NA(^USR(id))
  D PUT(.OUT,"id",id),PUT(.OUT,"email",$G(@b@("email"))),PUT(.OUT,"role",$G(@b@("role")))
  D PUT(.OUT,"active",+$G(@b@("active"))),PUT(.OUT,"email_verified",+$G(@b@("email_verified")))
  D PUT(.OUT,"email_verified_at",$G(@b@("email_verified_at"))),PUT(.OUT,"created_at",$G(@b@("created_at")))
  D PUT(.OUT,"updated_at",$G(@b@("updated_at")))
  I +$G(withHash) D PUT(.OUT,"password_hash",$G(@b@("password_hash")))
  Q

OUTITEM(OUT,idx,id) NEW b,n S b=$NA(^USR(id)),n=$NA(OUT("items",idx))
  S @n@("id")=id,@n@("email")=$G(@b@("email")),@n@("role")=$G(@b@("role"))
  S @n@("active")=+$G(@b@("active")),@n@("email_verified")=+$G(@b@("email_verified"))
  S @n@("email_verified_at")=$G(@b@("email_verified_at")),@n@("created_at")=$G(@b@("created_at"))
  Q

GETTOKEN(IN) NEW tok S tok=$G(IN("token")) I tok'="" Q tok
  N hdr S hdr=$G(IN("%HDR","Authorization")) I hdr'="",$E(hdr,1,7)="Bearer " Q $E(hdr,8,$L(hdr))
  Q ""

REQUIREAUTH(IN,UID,OUT) NEW tok S tok=$$GETTOKEN(.IN) I tok="" D SETHTTP(.OUT,401,"auth") Q 0
  N uid S uid=$$CHECK^SESAPI(tok) I 'uid D SETHTTP(.OUT,401,"auth") Q 0
  S UID=uid Q 1

REQUIREADMIN(IN,OUT) NEW uid S uid=0 I '$$REQUIREAUTH(.IN,.uid,.OUT) Q 0
  I $G(^USR(uid,"role"))'="admin" D SETHTTP(.OUT,403,"forbidden") Q 0
  Q 1

SETHTTP(OUT,code,msg) S OUT("%HTTP")=+$G(code,400) I $G(msg)'="" S OUT("error")=$G(msg) Q
LOW(s) Q $ZCONVERT(s,"L")
NUM(x,def) N r S r=+x I r=0,$G(x)'="0" S r=+$G(def,0) Q r Q r
NOW() Q $zd($zh,"YYYY-MM-DD")_"T"_$zd($zh,"24:60:SS")_"Z"
PUT(OUT,k,v) I $D(v) S OUT(k)=v Q  Q
