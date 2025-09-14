AUTHAPI ; MUMPS.IO - Users API (JSON over POST) for Quasar SSR backend
  QUIT
  ;
  ; Globals:
  ;   ^USR(id,"email")               email (lowercased)
  ;   ^USR(id,"password_hash")       Argon2id hash from Node (stored as-is)
  ;   ^USR(id,"role")                "user" | "admin"
  ;   ^USR(id,"active")              1|0
  ;   ^USR(id,"email_verified")      1|0
  ;   ^USR(id,"email_verified_at")   ISO8601 timestamp or ""
  ;   ^USR(id,"created_at")          ISO8601
  ;   ^USR(id,"updated_at")          ISO8601
  ;   ^USR("last")                   auto-increment last id
  ;
  ; Indexes:
  ;   ^USRIDX("email",lower)=id
  ;
  ; HTTP status convention:
  ;   Set OUT("%HTTP")=404 (or 409/400) for errors so the gateway returns that status.
  ;   Success: leave OUT("%HTTP") undefined (assumed 200).
  ;
  ; Utility:
  ;   $$LOW^AUTHAPI(s)         → lowercase
  ;   $$NOW^AUTHAPI()          → ISO8601 UTC timestamp "YYYY-MM-DDTHH:MM:SSZ"
  ;   $$NUM^AUTHAPI(x,def)     → numeric with default
  ;   SETREC/GETREC helpers

; ---------------------------
; POST /api/users/create
; IN:  IN("email"), IN("password_hash")
; OUT: id,email,role,active,email_verified,email_verified_at,created_at,updated_at
;      (HTTP 409 if email exists, 400 if invalid)
; ---------------------------
CREATE(IN,OUT) NEW email,hash,now,id,lower S (email,hash)="" K OUT
  S email=$G(IN("email")),hash=$G(IN("password_hash"))
  I email=""!(hash="") D SETHTTP(.OUT,400,"invalid") Q
  N eLower S eLower=$$LOW(email)
  ; ensure uniqueness with a short lock on the email key
  L +^USRIDX("email",eLower):3 E  D SETHTTP(.OUT,503,"busy") Q
  I $D(^USRIDX("email",eLower)) D  L -^USRIDX("email",eLower) Q
  . D SETHTTP(.OUT,409,"email_taken")
  ; allocate id
  L +^USR("last"):3 E  D SETHTTP(.OUT,503,"busy") L -^USRIDX("email",eLower) Q
  S id=$G(^USR("last"),0)+1,^USR("last")=id
  L -^USR("last")
  S now=$$NOW()
  ; persist
  S ^USR(id,"id")=id
  S ^USR(id,"email")=eLower
  S ^USR(id,"password_hash")=hash
  S ^USR(id,"role")="user"
  S ^USR(id,"active")=1
  S ^USR(id,"email_verified")=0
  S ^USR(id,"email_verified_at")=""
  S ^USR(id,"created_at")=now
  S ^USR(id,"updated_at")=now
  S ^USRIDX("email",eLower)=id
  L -^USRIDX("email",eLower)
  ; response (omit password_hash)
  D OUTREC(.OUT,id,0)
  Q

; ---------------------------
; POST /api/users/get
; IN:  IN("id")
; OUT: full user record (omit password_hash unless IN("with_hash")=1)
;      (HTTP 404 if not found)
; ---------------------------
GET(IN,OUT) NEW id,withHash S id=+$G(IN("id")),withHash=+$G(IN("with_hash")) K OUT
  I 'id D SETHTTP(.OUT,400,"invalid") Q
  I '$D(^USR(id)) D SETHTTP(.OUT,404,"not_found") Q
  D OUTREC(.OUT,id,withHash)
  Q

; ---------------------------
; POST /api/users/by-email
; IN:  IN("email")
; OUT: full user record INCLUDING password_hash (Node needs it to verify)
;      (HTTP 404 if not found)
; ---------------------------
BYEMAIL(IN,OUT) NEW email,id S email=$$LOW($G(IN("email"))) K OUT
  I email="" D SETHTTP(.OUT,400,"invalid") Q
  S id=$G(^USRIDX("email",email))
  I 'id D SETHTTP(.OUT,404,"not_found") Q
  D OUTREC(.OUT,id,1) ; include hash
  Q

; ---------------------------
; POST /api/users/update
; IN:  IN("id"), IN("patch","field")=value
; Allowed fields: role,active,email,email_verified,email_verified_at,password_hash,updated_at
; OUT: { ok: 1 } or HTTP 404 if id not found, 409 if email change collides
; ---------------------------
UPDATE(IN,OUT) NEW id S id=+$G(IN("id")) K OUT
  I 'id D SETHTTP(.OUT,400,"invalid") Q
  I '$D(^USR(id)) D SETHTTP(.OUT,404,"not_found") Q

  N now S now=$$NOW()
  N p S p=$NA(IN("patch"))
  N f S f=""
  ; handle email change with uniqueness check
  I $D(@p@("email")) D  I $G(OUT("%HTTP")) Q
  . N newE S newE=$$LOW($G(@p@("email")))
  . I newE="" D SETHTTP(.OUT,400,"invalid") Q
  . I newE=$G(^USR(id,"email")) Q  ; no-op
  . ; lock target email
  . L +^USRIDX("email",newE):3 E  D SETHTTP(.OUT,503,"busy") Q
  . I $D(^USRIDX("email",newE)) D  L -^USRIDX("email",newE) Q
  . . D SETHTTP(.OUT,409,"email_taken")
  . ; move index
  . N oldE S oldE=$G(^USR(id,"email")) I oldE'="" K ^USRIDX("email",oldE)
  . S ^USR(id,"email")=newE,^USRIDX("email",newE)=id
  . L -^USRIDX("email",newE)

  ; other fields
  I $D(@p@("role")) S ^USR(id,"role")=$G(@p@("role"))
  I $D(@p@("active")) S ^USR(id,"active")=+$G(@p@("active"))
  I $D(@p@("email_verified")) S ^USR(id,"email_verified")=+$G(@p@("email_verified"))
  I $D(@p@("email_verified_at")) S ^USR(id,"email_verified_at")=$G(@p@("email_verified_at"))
  I $D(@p@("password_hash")) S ^USR(id,"password_hash")=$G(@p@("password_hash"))
  ; updated_at (allow override but default to now)
  S ^USR(id,"updated_at")=$S($D(@p@("updated_at")):$G(@p@("updated_at")),1:now)

  S OUT("ok")=1
  Q

; ---------------------------
; POST /api/users/search
; IN:  IN("search"), IN("page"), IN("limit")
; OUT: total, items(n,{fields...}) ordered by id DESC
; ---------------------------
SEARCH(IN,OUT) NEW q,page,limit,off,total S (q,page,limit)=""
  K OUT
  S q=$$LOW($G(IN("search")))
  S page=$$NUM($G(IN("page")),1)
  S limit=$$NUM($G(IN("limit")),20) I limit<1 S limit=1
  I limit>100 S limit=100
  S off=(page-1)*limit

  N TMP S TMP=$NA(^TMP($J,"AUTHAPI","S"))
  K @TMP
  ; collect candidate ids (filter by email substring if provided)
  N e,id
  I q'="" D
  . S e="" F  S e=$O(^USRIDX("email",e)) Q:e=""  D
  . . I e[q S id=$G(^USRIDX("email",e)) I id>0 S @TMP@(id)=""
  E  D
  . ; no search: include all ids
  . S id=0 F  S id=$O(^USR(id)) Q:'id  S @TMP@(id)=""
  ; count
  S total=0,id=0 F  S id=$O(@TMP@(id)) Q:'id  S total=total+1

  S OUT("total")=total
  ; emit page slice in DESC id order
  N idx,emitted,curr,skipped S emitted=0,skipped=0
  S curr=$O(@TMP@(""),-1) ; highest id
  F  Q:(curr="")!(emitted'<limit)  D
  . I skipped<off S skipped=skipped+1 G NEXT
  . S idx=emitted+1,emitted=emitted+1
  . D OUTITEM(.OUT,idx,curr)
NEXT  . S curr=$O(@TMP@(curr),-1)
  K @TMP
  Q

; ---------------------------
; POST /api/admin/stats
; OUT: total, verified, active, admins
; ---------------------------
STATS(IN,OUT) K OUT N id,u,tot,ver,act,adm S (tot,ver,act,adm)=0
  S id=0 F  S id=$O(^USR(id)) Q:'id  D
  . S tot=tot+1
  . S:$G(^USR(id,"email_verified")) ver=ver+1
  . S:$G(^USR(id,"active")) act=act+1
  . S:$G(^USR(id,"role"))="admin" adm=adm+1
  S OUT("total")=tot,OUT("verified")=ver,OUT("active")=act,OUT("admins")=adm
  Q

; ===========================
; Helpers
; ===========================
; Emit a full record (withHash=1 includes password_hash)
OUTREC(OUT,id,withHash) NEW base S base=$NA(^USR(id))
  D PUT(.OUT,"id",id)
  D PUT(.OUT,"email",$G(@base@("email")))
  D PUT(.OUT,"role",$G(@base@("role")))
  D PUT(.OUT,"active",+$G(@base@("active")))
  D PUT(.OUT,"email_verified",+$G(@base@("email_verified")))
  D PUT(.OUT,"email_verified_at",$G(@base@("email_verified_at")))
  D PUT(.OUT,"created_at",$G(@base@("created_at")))
  D PUT(.OUT,"updated_at",$G(@base@("updated_at")))
  I +$G(withHash) D PUT(.OUT,"password_hash",$G(@base@("password_hash")))
  Q

; Emit one list item under OUT("items",n,...)
OUTITEM(OUT,idx,id) NEW base,node S base=$NA(^USR(id)),node=$NA(OUT("items",idx))
  S @node@("id")=id
  S @node@("email")=$G(@base@("email"))
  S @node@("role")=$G(@base@("role"))
  S @node@("active")=+$G(@base@("active"))
  S @node@("email_verified")=+$G(@base@("email_verified"))
  S @node@("email_verified_at")=$G(@base@("email_verified_at"))
  S @node@("created_at")=$G(@base@("created_at"))
  Q

; set standardized error
SETHTTP(OUT,code,msg)
  S OUT("%HTTP")=+$G(code,400)
  I $G(msg)'="" S OUT("error")=$G(msg)
  Q

; lower-case utility
LOW(s) NEW x S x=$G(s) Q $ZCONVERT(x,"L")

; numeric with default
NUM(x,def) N r S r=+x I r=0,$G(x)'="0" S r=+$G(def,0) Q r
  Q r

; ISO8601 now YYYY-MM-DDTHH:MM:SSZ
NOW() Q $zd($zh,"YYYY-MM-DD")_"T"_$zd($zh,"24:60:SS")_"Z"

; put scalar field if defined
PUT(OUT,key,val) I $D(val) S OUT(key)=val Q
  Q
