RESETSAPI ; MUMPS.IO - Password Reset API (JSON over POST)
	;#################################################################
	;#                                                               #
	;# Copyright (c) 2025 Ahmed Khaled Abdelrazek                    #
	;# All rights reserved.                                          #
	;#                                                               #
	;#   This source code contains the intellectual property         #
	;#   of its copyright holder(s), and is made available           #
	;#   under a license.  If you do not know the terms of           #
	;#   the license, please stop and do not read further.           #
	;#                                                               #
	;#################################################################
  QUIT
  ;
  ; Globals:
  ;   ^RESET(id,"jti")
  ;   ^RESET(id,"user_id")
  ;   ^RESET(id,"expires_at")    ; ISO8601 timestamp
  ;   ^RESET(id,"used")          ; 0|1
  ;   ^RESET(id,"created_at")    ; ISO8601
  ;   ^RESET("last")             ; auto-increment
  ;
  ; Index:
  ;   ^RESETIDX("jti",jti)=id
  ;
  ; Conventions:
  ;   Inputs via IN("key")=value
  ;   Outputs in OUT(...)
  ;   Set OUT("%HTTP") for non-200 responses

; ---------------------------------------------------------
; POST /api/resets/create
; IN:  IN("jti"), IN("user_id"), IN("expires_at")
; OUT: OUT("id") = new id
; HTTP: 400 invalid | 409 already exists | 503 busy (lock)
; ---------------------------------------------------------
CREATE(IN,OUT) NEW jti,uid,exp,now,id
  K OUT S jti=$G(IN("jti")),uid=+$G(IN("user_id")),exp=$G(IN("expires_at"))
  I jti=""!(uid<1)!(exp="") D SETHTTP(.OUT,400,"invalid") Q
  ; ensure uniqueness on jti
  L +^RESETIDX("jti",jti):3 E  D SETHTTP(.OUT,503,"busy") Q
  I $D(^RESETIDX("jti",jti)) D  L -^RESETIDX("jti",jti) Q
  . D SETHTTP(.OUT,409,"exists")
  ; allocate id
  L +^RESET("last"):3 E  D SETHTTP(.OUT,503,"busy") L -^RESETIDX("jti",jti) Q
  S id=$G(^RESET("last"),0)+1,^RESET("last")=id
  L -^RESET("last")
  ; persist
  S now=$$NOW()
  S ^RESET(id,"id")=id
  S ^RESET(id,"jti")=jti
  S ^RESET(id,"user_id")=uid
  S ^RESET(id,"expires_at")=exp
  S ^RESET(id,"used")=0
  S ^RESET(id,"created_at")=now
  S ^RESETIDX("jti",jti)=id
  L -^RESETIDX("jti",jti)
  S OUT("id")=id
  Q

; ---------------------------------------------------------
; POST /api/resets/get
; IN:  IN("jti"), IN("user_id")
; OUT: id, used, expires_at
; HTTP: 400 invalid | 404 not_found
; ---------------------------------------------------------
GET(IN,OUT) NEW jti,uid,id
  K OUT S jti=$G(IN("jti")),uid=+$G(IN("user_id"))
  I jti=""!(uid<1) D SETHTTP(.OUT,400,"invalid") Q
  S id=$G(^RESETIDX("jti",jti)) I 'id D SETHTTP(.OUT,404,"not_found") Q
  ; verify user matches token owner
  I +$G(^RESET(id,"user_id"))'=uid D SETHTTP(.OUT,404,"not_found") Q
  ; emit minimal shape Node expects
  S OUT("id")=id
  S OUT("used")=+$G(^RESET(id,"used"))
  S OUT("expires_at")=$G(^RESET(id,"expires_at"))
  Q

; ---------------------------------------------------------
; POST /api/resets/mark-used
; IN:  IN("id")
; OUT: ok=1
; HTTP: 400 invalid | 404 not_found
; ---------------------------------------------------------
USED(IN,OUT) NEW id
  K OUT S id=+$G(IN("id"))
  I 'id D SETHTTP(.OUT,400,"invalid") Q
  I '$D(^RESET(id)) D SETHTTP(.OUT,404,"not_found") Q
  S ^RESET(id,"used")=1
  S OUT("ok")=1
  Q

; (Optional) housekeeping — purge expired or used tokens older than N days
; DO PURGE^RESETSAPI(7) ; remove used or expired older than 7 days
PURGE(DAYS) NEW keep,now,id,exp,used,ts
  S keep=+$G(DAYS) I 'keep S keep=7
  S now=$$NOWTS()
  S id=0 F  S id=$O(^RESET(id)) Q:'id  D
  . S used=+$G(^RESET(id,"used")),exp=$G(^RESET(id,"expires_at"))
  . I used!($$CMPISO(exp,now)<0) D
  . . ; if older than keep days from created_at, delete
  . . S ts=$G(^RESET(id,"created_at"))
  . . I $$AGEISO(ts,now)'>keep Q
  . . N jti S jti=$G(^RESET(id,"jti")) I jti'="" K ^RESETIDX("jti",jti)
  . . K ^RESET(id)
  Q

; ===========================
; Helpers
; ===========================
SETHTTP(OUT,code,msg) S OUT("%HTTP")=+$G(code,400) I $G(msg)'="" S OUT("error")=$G(msg) Q

; ISO8601 now (UTC-ish)
NOW() Q $zd($zh,"YYYY-MM-DD")_"T"_$zd($zh,"24:60:SS")_"Z"
NOWold() NEW iso S iso=""
  NEW $ET,$ES S $ET="G NOWFALL"
  S iso=$ZD($H,3)
  s iso=$TR(iso," ","T")_"Z" Q iso
NOWFALL S iso="1970-01-01T00:00:00Z" Q iso

; Return a numeric timestamp-ish to compare when $ZDATETIME not available
NOWTS() NEW ts S ts=$H Q ts

; Compare two ISO strings A vs B (returns -1 if A<B, 0 if =, 1 if >).
; Simple lexicographic works for "YYYY-MM-DDTHH:MM:SSZ".
CMPISO(A,B) Q $S($G(A)=$G(B):0,$G(A)']$G(B):-1,1:1)

; Age in days between two ISO timestamps (rough; day-level granularity).
AGEISO(A,B) NEW d S d=$E(A,1,10),d=$TR(d,"-","") NEW e S e=$E(B,1,10),e=$TR(e,"-","")
  Q $$ABSDIFF(+d,+e)

ABSDIFF(X,Y) NEW D S D=X-Y Q $S(D<0:-D,1:D)