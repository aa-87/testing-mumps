PROBAPI ; Minimal CGI for listing and fetching problems
  NEW QS,ENV SET QS=$$GETENV("QUERY_STRING")
  NEW id SET id=$$QGET(QS,"id")
  IF id'="" DO ONE(id) QUIT

  NEW facets SET facets=$$QGET(QS,"facets")
  IF facets=1 DO FACETS QUIT

  DO LIST(QS) QUIT

; ---------- LIST ----------
LIST(QS)
  NEW search SET search=$$QGET(QS,"search")
  NEW sort SET sort=$$QGET(QS,"sort") S:sort="" sort="newest"
  NEW page SET page=$$NUM($$QGET(QS,"page"),1)
  NEW limit SET limit=$$NUM($$QGET(QS,"limit"),20) IF limit<1 SET limit=20
  NEW d,di,hasDiff SET hasDiff=0
  NEW diffs KILL diffs
  FOR di=1:1:$L(QS,"&") DO  ; collect repeated difficulty params
  . NEW kv SET kv=$P(QS,"&",di)
  . IF $P(kv,"=",1)="difficulty" SET d=$$URLDEC($P(kv,"=",2)),diffs(d)="" SET hasDiff=1

  NEW items,total SET total=0
  NEW ID SET ID=0
  FOR  SET ID=$O(^PROB(ID)) QUIT:'ID  DO
  . NEW T,D,OK SET OK=1
  . SET T=$G(^PROB(ID,"title")),D=$G(^PROB(ID,"difficulty"))
  . IF search'="" DO  SET OK=$$MATCH(ID,search)
  . . ; MATCH checks title/slug/tags/desc
  . IF 'OK QUIT
  . IF hasDiff,($D(diffs(D))=0) QUIT
  . SET total=total+1
  . SET items(total)=ID

  ; sort
  DO SORT(.items,total,sort)

  ; paging
  NEW start,end SET start=((page-1)*limit)+1 SET end=start+limit-1
  IF start>total SET start=1,end=0
  ; output
  DO HDR
  WRITE "{""page"":"_page_",""limit"":"_limit_",""total"":"_total_",""items"":["
  NEW first SET first=1
  NEW i FOR i=start:1:end QUIT:i>total  DO
  . IF 'first WRITE "," ELSE  SET first=0
  . DO WRITEITEM(items(i))
  WRITE "]}"
  QUIT

; ---------- ONE ----------
ONE(IDVAL)
  NEW id SET id=$$IDFROM(IDVAL)
  IF id=0 DO HDR WRITE "{}" QUIT
  DO HDR DO WRITEOBJ(id) QUIT

; ---------- FACETS ----------
FACETS
  NEW cE,cM,cH SET (cE,cM,cH)=0
  NEW tagc KILL tagc
  NEW ID SET ID=0
  FOR  SET ID=$O(^PROB(ID)) QUIT:'ID  DO
  . NEW D SET D=$G(^PROB(ID,"difficulty"))
  . IF D="Easy" SET cE=cE+1
  . IF D="Medium" SET cM=cM+1
  . IF D="Hard" SET cH=cH+1
  . NEW i,tgs SET tgs=$G(^PROB(ID,"tags"))
  . FOR i=1:1:$L(tgs,"^") SET t=$P(tgs,"^",i) QUIT:t=""  SET tagc(t)=$G(tagc(t))+1
  DO HDR
  WRITE "{""difficulty"":{""Easy"":"_cE_",""Medium"":"_cM_",""Hard"":"_cH_"},""tags"":["
  NEW first SET first=1
  NEW tag SET tag=""
  FOR  SET tag=$O(tagc(tag)) QUIT:tag=""  DO
  . IF 'first WRITE "," ELSE  SET first=0
  . WRITE "{""tag"":"""_$$ESC(tag)_""",""count"":"_tagc(tag)_"}"
  WRITE "]}"
  QUIT

; ---------- Helpers ----------
HDR ; HTTP headers
  WRITE "Status: 200 OK",!
  WRITE "Content-Type: application/json",!,!
  QUIT

WRITEITEM(id)
  NEW t SET t="{""id"":"_id_",""title"":"""_$$ESC($G(^PROB(id,"title")))_""",""slug"":"""_$$ESC($G(^PROB(id,"slug")))_""",""difficulty"":"""_$$ESC($G(^PROB(id,"difficulty")))_""",""tags"":["
  WRITE t
  NEW first,i,x SET first=1
  NEW tags SET tags=$G(^PROB(id,"tags"))
  FOR i=1:1:$L(tags,"^") SET x=$P(tags,"^",i) QUIT:x=""  DO
  . IF 'first WRITE "," ELSE  SET first=0
  . WRITE """"_$$ESC(x)_""""
  WRITE "],""acceptance"":"_$G(^PROB(id,"accept"),0)
  WRITE "}"
  QUIT

WRITEOBJ(id)
  WRITE "{"
  WRITE """id"":"_id_","
  WRITE """title"":"""_$$ESC($G(^PROB(id,"title")))_""","
  WRITE """slug"":"""_$$ESC($G(^PROB(id,"slug")))_""","
  WRITE """difficulty"":"""_$$ESC($G(^PROB(id,"difficulty")))_""","
  WRITE """tags"":["
  NEW first,i,x SET first=1
  NEW tags SET tags=$G(^PROB(id,"tags"))
  FOR i=1:1:$L(tags,"^") SET x=$P(tags,"^",i) QUIT:x=""  DO
  . IF 'first WRITE "," ELSE  SET first=0
  . WRITE """"_$$ESC(x)_""""
  WRITE "],"
  WRITE """acceptance"":"_$G(^PROB(id,"accept"),0)_","
  WRITE """description"":"""_$$ESC($G(^PROB(id,"desc")))_""""
  WRITE "}"
  QUIT

IDFROM(v) ; resolve id or slug
  NEW id SET id=+v IF id>0 QUIT id
  ; linear scan by slug (small demo set)
  SET id=0
  FOR  SET id=$O(^PROB(id)) QUIT:'id  IF $G(^PROB(id,"slug"))=v QUIT
  QUIT id

SORT(items,total,mode)
  IF mode="title" DO  QUIT
  . NEW map,idx SET idx=0
  . NEW i FOR i=1:1:total SET id=items(i),map($$LOW($G(^PROB(id,"title"))),id)=""
  . KILL items SET i=0
  . NEW t SET t="" FOR  SET t=$O(map(t)) Q:t=""  DO
  . . NEW id SET id=0 FOR  SET id=$O(map(t,id)) Q:'id  SET i=i+1,items(i)=id
  QUIT:mode="title"
  IF mode="difficulty" DO  QUIT
  . ; Hard > Medium > Easy
  . NEW score,id,i FOR i=1:1:total SET id=items(i) DO
  . . SET score(i)=$S($G(^PROB(id,"difficulty"))="Hard":3,$G(^PROB(id,"difficulty"))="Medium":2,1:1)_":"_id
  . KILL items SET i=0
  . NEW k SET k="" FOR  SET k=$O(score(k),-1) Q:k=""  DO
  . . NEW id SET id=$P(score(k),":",2) SET i=i+1,items(i)=id
  QUIT:mode="difficulty"
  IF mode="hot" DO  QUIT  ; demo: treat lower id as older/less hot, random-ish fallback
  . ; keep as-is or shuffle lightly (omitted for brevity)
  . QUIT
  ; newest (default): sort by id desc
  NEW rev,i SET rev=0
  FOR i=1:1:(total\2) DO
  . NEW tmp SET tmp=items(i) SET items(i)=items(total-i+1) SET items(total-i+1)=tmp
  QUIT

MATCH(id,term)
  NEW q SET q=$$LOW(term)
  IF $$CONTAINS($$LOW($G(^PROB(id,"title"))),q) QUIT 1
  IF $$CONTAINS($$LOW($G(^PROB(id,"slug"))),q) QUIT 1
  IF $$CONTAINS($$LOW($G(^PROB(id,"desc"))),q) QUIT 1
  NEW i,tgs SET tgs=$G(^PROB(id,"tags"))
  FOR i=1:1:$L(tgs,"^") QUIT:$P(tgs,"^",i)=""  IF $$CONTAINS($$LOW($P(tgs,"^",i)),q) QUIT 1
  QUIT 0

; ---------- tiny utils ----------
GETENV(n) QUIT $ZTRNLNM(n)

QGET(QS,name) ; get single query value
  NEW i,kv,k,v
  FOR i=1:1:$L(QS,"&") SET kv=$P(QS,"&",i),k=$P(kv,"=",1),v=$P(kv,"=",2,999) IF k=name QUIT $$URLDEC(v)
  QUIT ""

NUM(x,def) NEW n SET n=+x QUIT $S(n>0:n,1:def)

LOW(s) QUIT $ZCONVERT($G(s),"L")

CONTAINS(hay,needle) QUIT hay[needle

URLDEC(s)
  NEW i,c,out SET s=$TRANSLATE($G(s),"+"," ")
  SET out=""
  FOR i=1:1:$L(s) DO
  . SET c=$E(s,i)
  . IF c="%"&(i+2'>$L(s)) DO  SET i=i+2 QUIT
  . . NEW hex SET hex=$E(s,i+1,i+2)
  . . NEW ch SET ch=$C($ZHEX(hex))
  . . SET out=out_ch
  . ELSE  SET out=out_c
  QUIT out

ESC(s) ; JSON escape
  NEW i,c,out SET out=""
  FOR i=1:1:$L($G(s)) SET c=$E(s,i) DO
  . IF c="\" SET out=out_"\\"
  . ELSE  IF c="""" SET out=out_""""""
  . ELSE  IF c=$C(9) SET out=out_"\\t"
  . ELSE  IF c=$C(10) SET out=out_"\\n"
  . ELSE  IF c=$C(13) SET out=out_"\\r"
  . ELSE  SET out=out_c
  QUIT out
