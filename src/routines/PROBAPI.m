PROBAPI ; POST-only JSON API helpers for Problems
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
 ; Each entrypoint below expects:
 ;   .IN  = input associative array (provided by your web layer from POST body)
 ;   .OUT = output associative array (this routine fills it; your web layer serializes it)

 ;------------------------------------------------------------
 ; POST /api/problems/list  →  DO LIST(.IN,.OUT)
 ;  IN("search")               : optional, case-insensitive substring
 ;  IN("sort")                 : "newest" (default) | "title" | "difficulty" | "hot"
 ;  IN("page")                 : 1-based (default 1)
 ;  IN("limit")                : per-page (default 20)
 ;  IN("difficulty","Easy")=1  : optional multi-select flags ("Easy","Medium","Hard")
 ;  IN("difficulty","Medium")=1
 ;  IN("difficulty","Hard")=1
 ;  OUT("page"), OUT("limit"), OUT("total")
 ;  OUT("items",n,"id"|"title"|"slug"|"difficulty"|"acceptance")
 ;  OUT("items",n,"tags",t) = tag strings (1..T)
 ;------------------------------------------------------------
LIST(IN,OUT) ;
  NEW search,sort,page,limit SET search=$GET(IN("search"))
  SET sort=$$NZ("newest",$GET(IN("sort")))
  SET page=+$GET(IN("page")) IF page<1 SET page=1
  SET limit=+$GET(IN("limit")) IF limit<1 SET limit=20

  NEW hasDiff SET hasDiff=0
  NEW diffs KILL diffs
  IF $GET(IN("difficulty","Easy"))  SET diffs("Easy")=1,hasDiff=1
  IF $GET(IN("difficulty","Medium")) SET diffs("Medium")=1,hasDiff=1
  IF $GET(IN("difficulty","Hard"))   SET diffs("Hard")=1,hasDiff=1

  NEW items,total SET total=0
  NEW ID SET ID=0
  FOR  SET ID=$O(^PROB(ID)) QUIT:'ID  DO
  . NEW OK SET OK=1
  . IF search'="" SET OK=$$MATCH(ID,search) IF 'OK QUIT
  . IF hasDiff,'$DATA(diffs($GET(^PROB(ID,"difficulty")))) QUIT
  . SET total=total+1,items(total)=ID

  DO SORT(.items,total,sort)

  NEW start,end SET start=((page-1)*limit)+1,end=start+limit-1
  IF start>total SET start=1,end=0

  ; shape OUT
  KILL OUT
  SET OUT("page")=page,OUT("limit")=limit,OUT("total")=total
  NEW idx SET idx=0
  NEW i FOR i=start:1:end QUIT:i>total  DO
  . NEW id SET id=items(i)
  . SET idx=idx+1
  . DO PUTITEM(.OUT,"items",idx,id)
  QUIT

 ;------------------------------------------------------------
 ; POST /api/problems/get  →  DO GET(.IN,.OUT)
 ;  IN("id")   : numeric id (preferred)  OR
 ;  IN("slug") : string slug
 ;  OUT("id"|"title"|"slug"|"difficulty"|"acceptance"|"description")
 ;  OUT("tags",t) = tag strings (1..T)
 ;------------------------------------------------------------
GET(IN,OUT) ;
  NEW id
  IF $DATA(IN("id"))   SET id=+IN("id")
  ELSE  IF $GET(IN("slug"))'="" SET id=$$RESOLVE(IN("slug"))
  ELSE  SET id=0

  KILL OUT
  IF id'>0 SET OUT("error")="not_found" QUIT
  IF '$DATA(^PROB(id)) SET OUT("error")="not_found" QUIT

  DO PUTOBJ(.OUT,id)
  QUIT

 ;------------------------------------------------------------
 ; POST /api/problems/facets  →  DO FACETS(.IN,.OUT)
 ;  OUT("difficulty","Easy"|"Medium"|"Hard") = counts
 ;  OUT("tags",n,"tag"), OUT("tags",n,"count")
 ;------------------------------------------------------------
FACETS(IN,OUT) ;
  NEW cE,cM,cH SET (cE,cM,cH)=0
  NEW tagc KILL tagc

  NEW ID SET ID=0
  FOR  SET ID=$O(^PROB(ID)) QUIT:'ID  DO
  . NEW D SET D=$GET(^PROB(ID,"difficulty"))
  . IF D="Easy"  SET cE=cE+1
  . IF D="Medium" SET cM=cM+1
  . IF D="Hard"   SET cH=cH+1
  . NEW i,tgs SET tgs=$GET(^PROB(ID,"tags"))
  . FOR i=1:1:$L(tgs,"^") NEW t SET t=$P(tgs,"^",i) QUIT:t=""  SET tagc(t)=$GET(tagc(t))+1

  KILL OUT
  SET OUT("difficulty","Easy")=cE
  SET OUT("difficulty","Medium")=cM
  SET OUT("difficulty","Hard")=cH

  NEW n SET n=0
  NEW tag SET tag=""
  FOR  SET tag=$O(tagc(tag)) QUIT:tag=""  DO
  . SET n=n+1
  . SET OUT("tags",n,"tag")=tag
  . SET OUT("tags",n,"count")=tagc(tag)
  QUIT

 ;==========================
 ; Internals / helpers
 ;==========================

 ; Add a compact list item into OUT("items",n,*)
PUTITEM(OUT,ROOT,IDX,ID) ;
  NEW base SET base=ROOT_","_IDX
  SET OUT(ROOT,IDX,"id")=ID
  SET OUT(ROOT,IDX,"title")=$GET(^PROB(ID,"title"))
  SET OUT(ROOT,IDX,"slug")=$GET(^PROB(ID,"slug"))
  SET OUT(ROOT,IDX,"difficulty")=$GET(^PROB(ID,"difficulty"))
  SET OUT(ROOT,IDX,"acceptance")=+$GET(^PROB(ID,"accept"))
  DO PUTTAGS(.OUT,ROOT,IDX,$GET(^PROB(ID,"tags")))
  QUIT

 ; Add full object fields into OUT(*)
PUTOBJ(OUT,ID) ;
  SET OUT("id")=ID
  SET OUT("title")=$GET(^PROB(ID,"title"))
  SET OUT("slug")=$GET(^PROB(ID,"slug"))
  SET OUT("difficulty")=$GET(^PROB(ID,"difficulty"))
  SET OUT("acceptance")=+$GET(^PROB(ID,"accept"))
  SET OUT("description")=$GET(^PROB(ID,"desc"))
  DO PUTTAGS(.OUT,"tags",0,$GET(^PROB(ID,"tags")))
  QUIT

 ; Helper to expand caret-separated tags into array nodes
 ;  If ROOT="items",IDX>0 → OUT("items",IDX,"tags",1..n)
 ;  If ROOT="tags", IDX=0 → OUT("tags",1..n)
PUTTAGS(OUT,ROOT,IDX,TAGSTR) ;
  NEW i,t,n SET n=0
  FOR i=1:1:$L(TAGSTR,"^") SET t=$P(TAGSTR,"^",i) QUIT:t=""  DO
  . SET n=n+1
  . IF IDX>0 SET OUT(ROOT,IDX,"tags",n)=t
  . ELSE      SET OUT(ROOT,n)=t
  QUIT

 ; Case-insensitive match over title/slug/desc/tags
MATCH(ID,TERM) ;
  NEW q,a,b SET q=$$LOW(TERM),(a,b)=0
  IF $$CONTAINS($$LOW($GET(^PROB(ID,"title"))),q) QUIT 1
  IF $$CONTAINS($$LOW($GET(^PROB(ID,"slug"))),q) QUIT 1
  IF $$CONTAINS($$LOW($GET(^PROB(ID,"desc"))),q) QUIT 1
  NEW i,tgs SET tgs=$GET(^PROB(ID,"tags"))
  FOR i=1:1:$L(tgs,"^") QUIT:$P(tgs,"^",i)=""  IF $$CONTAINS($$LOW($P(tgs,"^",i)),q) s b=1,a=1
  i a q b
  QUIT 0

 ; Sort items(1..total) in-place by mode
SORT(items,total,mode) ;
  IF mode="title" DO  QUIT
  . NEW map,i,id SET i=0
  . KILL map
  . FOR i=1:1:total SET id=items(i),map($$LOW($GET(^PROB(id,"title"))),id)=""
  . KILL items SET i=0
  . NEW k SET k=""
  . FOR  SET k=$O(map(k)) Q:k=""  DO
  . . NEW id SET id=0
  . . FOR  SET id=$O(map(k,id)) Q:'id  SET i=i+1,items(i)=id  ; ASC
  IF mode="difficulty" DO  QUIT  ; Hard > Medium > Easy
  . NEW score,i,id
  . FOR i=1:1:total SET id=items(i) DO
  . . SET score(i)=$S($GET(^PROB(id,"difficulty"))="Hard":3,$GET(^PROB(id,"difficulty"))="Medium":2,1:1)_":"_id
  . NEW k SET k="",i=0 KILL items
  . FOR  SET k=$O(score(k),-1) Q:k=""  SET i=i+1,items(i)=$P(score(k),":",2)
  ; "hot": keep original order for now (placeholder)
  ; default "newest": id DESC
  NEW j FOR j=1:1:(total\2) NEW tmp SET tmp=items(j) SET items(j)=items(total-j+1) SET items(total-j+1)=tmp
  QUIT

 ; Resolve id from numeric or slug
RESOLVE(v) ;
  NEW id SET id=+v IF id>0 QUIT id
  SET id=0 FOR  SET id=$O(^PROB(id)) Q:'id  IF $GET(^PROB(id,"slug"))=v QUIT
  QUIT id

 ; utils
NZ(def,x) QUIT $S($GET(x)'="":x,1:def)
LOW(s) QUIT $ZCONVERT($GET(s),"L")
CONTAINS(hay,needle) QUIT hay[needle