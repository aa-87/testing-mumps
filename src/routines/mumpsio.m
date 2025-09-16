mumspio ;
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
main 
 	n route s route=$na(^MI(":WS","ROUTES")) k @route
 	n method f method="POST","OPTIONS" d
 	. s @route@(method,"api/problems/list","lisProblemst^mumpsio")=""
 	. s @route@(method,"api/problems/list","getProblems^mumpsio")=""
 	. s @route@(method,"api/problems/list","facetsProblems^mumpsio")=""
 	. s @route@(method,"api/users/create","userCreate^mumpsio")=""
 	. s @route@(method,"api/users/get","getUser^mumpsio")=""
 	. s @route@(method,"api/users/by-email","userByEmail^mumpsio")=""
 	. s @route@(method,"api/users/update","updateUser^mumpsio")=""
 	. s @route@(method,"api/users/search","searchUser^mumpsio")=""
 	. s @route@(method,"api/admin/stats","adminStats^mumpsio")=""
 	. s @route@(method,"api/resets/create","resetsCreate^mumpsio")=""
 	. s @route@(method,"api/resets/get","resetsGet^mumpsio")=""
 	. s @route@(method,"api/resets/mark-used","resetsMarkUsed^mumpsio")=""
 	q
zl  ;export ydb_routines=`ydb -run %XCMD 'W $P($P($ZRO,"(",1,2),")")_" "_"$PWD/src/routines"_")"_$P($ZRO,")",2,$L($ZRO,")"))'` 
	zl "mumpsio.m"
	zl "PROBAPI.m"
	zl "AUTHAPI.m"
	zl "RESETSAPI.m"
	q
	; --------------------------- 
 	; POST /api/problems/list
 	; IN("search")="tree",  IN("sort")="title" IN("page")=2 IN("limit")=10 IN("difficulty","Easy")=1 IN("difficulty","Medium")=1
	; OUT("page")=2 OUT("limit")=10 OUT("total")=37 OUT("items",1,"id")=9 OUT("items",1,"title")="Binary Tree Inorder Traversal"
	; OUT("items",1,"slug")="bt-inorder" ;OUT("items",1,"difficulty")="Easy" OUT("items",1,"acceptance")=71.0 OUT("items",1,"tags",1)="tree"
	; OUT("items",1,"tags",2)="stack"
listProblems(%Q,%R,%A) 
	s %R("header","Access-Control-Allow-Origin")="*"
	s %R("header","Access-Control-Allow-Headers")="Origin, X-Requested-With, Content-Type, Accept, auth, jwt"
	s %R("mime")="application/json"
	i %Q("method")="OPTIONS" q
	I '$D(@%Q("body")) Q
	n in,out
	d decode^aajson(%Q("body"),$na(in))
	d LIST^PROBAPI(.in,.out)
	i $g(out("%HTTP")) s HTTPERR=out("%HTTP") k out("%HTTP")
	d encode^aajson($na(out),%R)
	q
	; ---------------------------
 	; POST /api/problems/get
 	; IN("slug")="lru-cache"
 	; OUT("id")=3 OUT("title")="LRU Cache" OUT("slug")="lru-cache"  OUT("difficulty")="Medium"
	; OUT("acceptance")=49.8  OUT("description")="Design an LRU cache." OUT("tags",1)="design"  OUT("tags",2)="hash-table"
getProblems(%Q,%R,%A)	
 	S %R("mime")="application/json"
	S %R("header","Access-Control-Allow-Origin")="*"
	S %R("header","Access-Control-Allow-Headers")="Origin, X-Requested-With, Content-Type, Accept, auth, jwt"
	i %Q("method")="OPTIONS" q
	I '$D(@%Q("body")) Q
	n in,out
	d decode^aajson(%Q("body"),$na(in))
	d GET^PROBAPI(.in,.out)
	i $g(out("%HTTP")) s HTTPERR=out("%HTTP") k out("%HTTP")
	d encode^aajson($na(out),%R)
	q
	; ---------------------------
 	; POST /api/problems/facets
 	; OUT("difficulty","Easy")=4  OUT("difficulty","Medium")=4  OUT("difficulty","Hard")=2
 	; OUT("tags",1,"tag")="graph" OUT("tags",1,"count")=2 ....
facetsProblems(%Q,%R,%A)
 	S %R("mime")="application/json"
	S %R("header","Access-Control-Allow-Origin")="*"
	S %R("header","Access-Control-Allow-Headers")="Origin, X-Requested-With, Content-Type, Accept, auth, jwt"
	i %Q("method")="OPTIONS" q
	I '$D(@%Q("body")) Q
	n in,out
	d decode^aajson(%Q("body"),$na(in))
	d FACETS^PROBAPI(.in,.out)
	i $g(out("%HTTP")) s HTTPERR=out("%HTTP") k out("%HTTP")
	d encode^aajson($na(out),%R)
	q
	; ---------------------------
	; POST /api/users/create 
	; IN:  IN("email"), IN("password_hash")
	; OUT: id,email,role,active,email_verified,email_verified_at,created_at,updated_at
	;      (HTTP 409 if email exists, 400 if invalid)
userCreate(%Q,%R,%A)	
 	S %R("mime")="application/json"
	S %R("header","Access-Control-Allow-Origin")="*"
	S %R("header","Access-Control-Allow-Headers")="Origin, X-Requested-With, Content-Type, Accept, auth, jwt"
	i %Q("method")="OPTIONS" q
	I '$D(@%Q("body")) Q
	n in,out
	d decode^aajson(%Q("body"),$na(in))
	d CREATE^AUTHAPI(.in,.out)
	i $g(out("%HTTP")) s HTTPERR=out("%HTTP") k out("%HTTP")
	d encode^aajson($na(out),%R)
	q
	; ---------------------------
	; POST /api/users/get
	; IN:  IN("id")
	; OUT: full user record (omit password_hash unless IN("with_hash")=1)
	;      (HTTP 404 if not found)
getUser(%Q,%R,%A)	
 	S %R("mime")="application/json"
	S %R("header","Access-Control-Allow-Origin")="*"
	S %R("header","Access-Control-Allow-Headers")="Origin, X-Requested-With, Content-Type, Accept, auth, jwt"
	i %Q("method")="OPTIONS" q
	I '$D(@%Q("body")) Q
	n in,out
	d decode^aajson(%Q("body"),$na(in))
	d GET^AUTHAPI(.in,.out)
	i $g(out("%HTTP")) s HTTPERR=out("%HTTP") k out("%HTTP")
	d encode^aajson($na(out),%R)
	q
	; ---------------------------
	; POST /api/users/by-email
	; IN:  IN("email")
	; OUT: full user record INCLUDING password_hash (Node needs it to verify)
	;      (HTTP 404 if not found)
userByEmail(%Q,%R,%A)	
 	S %R("mime")="application/json"
	S %R("header","Access-Control-Allow-Origin")="*"
	S %R("header","Access-Control-Allow-Headers")="Origin, X-Requested-With, Content-Type, Accept, auth, jwt"
	i %Q("method")="OPTIONS" q
	I '$D(@%Q("body")) Q
	n in,out
	d decode^aajson(%Q("body"),$na(in))
	d BYEMAIL^AUTHAPI(.in,.out)
	i $g(out("%HTTP")) s HTTPERR=out("%HTTP") k out("%HTTP")
	d encode^aajson($na(out),%R)
	q
	; ---------------------------
	; POST /api/users/update
	; IN:  IN("id"), IN("patch","field")=value
	; Allowed fields: role,active,email,email_verified,email_verified_at,password_hash,updated_at
	; OUT: { ok: 1 } or HTTP 404 if id not found, 409 if email change collides
updateUser(%Q,%R,%A)	
 	S %R("mime")="application/json"
	S %R("header","Access-Control-Allow-Origin")="*"
	S %R("header","Access-Control-Allow-Headers")="Origin, X-Requested-With, Content-Type, Accept, auth, jwt"
	i %Q("method")="OPTIONS" q
	I '$D(@%Q("body")) Q
	n in,out
	d decode^aajson(%Q("body"),$na(in))
	d UPDATE^AUTHAPI(.in,.out)
	i $g(out("%HTTP")) s HTTPERR=out("%HTTP") k out("%HTTP")
	d encode^aajson($na(out),%R)
	q
	; ---------------------------
	; POST /api/users/search
	; IN:  IN("search"), IN("page"), IN("limit")
	; OUT: total, items(n,{fields...}) ordered by id DESC
searchUser(%Q,%R,%A)	
 	S %R("mime")="application/json"
	S %R("header","Access-Control-Allow-Origin")="*"
	S %R("header","Access-Control-Allow-Headers")="Origin, X-Requested-With, Content-Type, Accept, auth, jwt"
	i %Q("method")="OPTIONS" q
	I '$D(@%Q("body")) Q
	n in,out
	d decode^aajson(%Q("body"),$na(in))
	d SEARCH^AUTHAPI(.in,.out)
	i $g(out("%HTTP")) s HTTPERR=out("%HTTP") k out("%HTTP")
	d encode^aajson($na(out),%R)
	q
; ---------------------------
; POST /api/admin/stats
; OUT: total, verified, active, admins
; ---------------------------
adminStats(%Q,%R,%A)	
 	S %R("mime")="application/json"
	S %R("header","Access-Control-Allow-Origin")="*"
	S %R("header","Access-Control-Allow-Headers")="Origin, X-Requested-With, Content-Type, Accept, auth, jwt"
	i %Q("method")="OPTIONS" q
	I '$D(@%Q("body")) Q
	n in,out
	d decode^aajson(%Q("body"),$na(in))
	d STATS^AUTHAPI(.in,.out)
	i $g(out("%HTTP")) s HTTPERR=out("%HTTP") k out("%HTTP")
	d encode^aajson($na(out),%R)
	q
; ---------------------------------------------------------
; POST /api/resets/create
; IN:  IN("jti"), IN("user_id"), IN("expires_at")
; OUT: OUT("id") = new id
; HTTP: 400 invalid | 409 already exists | 503 busy (lock)
resetsCreate(%Q,%R,%A)	
 	S %R("mime")="application/json"
	S %R("header","Access-Control-Allow-Origin")="*"
	S %R("header","Access-Control-Allow-Headers")="Origin, X-Requested-With, Content-Type, Accept, auth, jwt"
	i %Q("method")="OPTIONS" q
	I '$D(@%Q("body")) Q
	n in,out
	d decode^aajson(%Q("body"),$na(in))
	d CREATE^RESETSAPI(.in,.out)
	i $g(out("%HTTP")) s HTTPERR=out("%HTTP") k out("%HTTP")
	d encode^aajson($na(out),%R)
	q
; ---------------------------------------------------------
; POST /api/resets/get
; IN:  IN("jti"), IN("user_id")
; OUT: id, used, expires_at
; HTTP: 400 invalid | 404 not_found
resetsGet(%Q,%R,%A)	
 	S %R("mime")="application/json"
	S %R("header","Access-Control-Allow-Origin")="*"
	S %R("header","Access-Control-Allow-Headers")="Origin, X-Requested-With, Content-Type, Accept, auth, jwt"
	i %Q("method")="OPTIONS" q
	I '$D(@%Q("body")) Q
	n in,out
	d decode^aajson(%Q("body"),$na(in))
	d GET^RESETSAPI(.in,.out)
	i $g(out("%HTTP")) s HTTPERR=out("%HTTP") k out("%HTTP")
	d encode^aajson($na(out),%R)
	q
; ---------------------------------------------------------
; POST /api/resets/mark-used
; IN:  IN("id")
; OUT: ok=1
; HTTP: 400 invalid | 404 not_found
resetsMarkUsed(%Q,%R,%A)	
 	S %R("mime")="application/json"
	S %R("header","Access-Control-Allow-Origin")="*"
	S %R("header","Access-Control-Allow-Headers")="Origin, X-Requested-With, Content-Type, Accept, auth, jwt"
	i %Q("method")="OPTIONS" q
	I '$D(@%Q("body")) Q
	n in,out
	d decode^aajson(%Q("body"),$na(in))
	d USED^RESETSAPI(.in,.out)
	i $g(out("%HTTP")) s HTTPERR=out("%HTTP") k out("%HTTP")
	d encode^aajson($na(out),%R)
	q
