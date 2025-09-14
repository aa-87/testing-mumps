PROBIMPT ; Import LeetCodeDataset JSONL into ^PROB using external JSON->global decoder
  ;
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
   ; Public entry:
  ;   DO IMPT^PROBIMPT("/path/LeetCodeDataset-v2-train-problems.jsonl",1000)
  ; Notes:
  ;   * Expects an external decoder to fill a global tree from a JSON string.
  ;   * See DECODE placeholder below and replace with your JSON library call.
  ;
  Q
IMPORT
    N SRC,line,CD S CD=$P
    S SRC="leetcodedata/data/data/LeetCodeDataset-v0.1.0-train.jsonl"
    O SRC:(readonly)
    F  U SRC R line Q:$zeof  D
	. S ^AA($I(^AA))=line
	C SRC
	U CD W "DONE!"
	Q 
  	;
IMPT ;(FILE,MAX) ; Import up to MAX lines (omit MAX to import all)
  ;NEW $ET,$ES SET $ET="DO ERR^PROBIMPT"
  ;IF $GET(FILE)="" WRITE "IMPT: missing FILE",! QUIT
  ;NEW cnt SET cnt=0
  ;NEW last SET last=$GET(^PROB("last"),0);

  ;; Optional: initialize when ^PROB empty
  ;IF '$DATA(^PROB) DO
  ;. KILL ^PROB,^PROBIDX
  ;. SET last=0
  ;NEW ROOT SET ROOT=$NAME(^TMP($J,"PROBIMPT","OBJ"))
  ;OPEN FILE:readonly:5 
  ;USE FILE
  ;NEW line SET line=""
  ;FOR  READ line QUIT:$ZEOF  DO  QUIT:($GET(MAX)&cnt'<$G(MAX))
  NEW cnt SET cnt=0 S MAX=9999999999999999999999999999999999999
  NEW last SET last=$GET(^PROB("last"),0);
  NEW ROOT SET ROOT=$NAME(^TMP($J,"PROBIMPT","OBJ"))
  KILL ^PROB,^PROBIDX  SET last=0
  NEW line,A SET line="",A=""
  FOR  S A=$O(^AA(A)) Q:A=""  DO  QUIT:($GET(MAX)&cnt'<$G(MAX))
  . S line=^AA(A)
  . KILL @ROOT
  . IF '$$DECODE(line,ROOT) QUIT  ; skip if decode failed
  . ; Extract fields from the decoded tree
  . NEW slug SET slug=$$VAL(ROOT,"task_id")
  . NEW diff SET diff=$$VAL(ROOT,"meta^difficulty")
  . NEW qtitle SET qtitle=$$VAL(ROOT,"question_title")
  . IF qtitle="" SET qtitle=$$VAL(ROOT,"meta^question_title")
  . ; Normalize & fallbacks
  . IF slug="" QUIT  ; cannot proceed without a key
  . SET diff=$$NORMDIFF(diff)
  . NEW title SET title=$SELECT(qtitle'="":qtitle,1:$$TITLECASE(slug))
  . NEW desc  SET desc=$SELECT(qtitle'="":qtitle,1:title)
  . ; Derive tags & acceptance
  . NEW tags SET tags=$$TAGS(title_" "_desc_" "_slug)
  . NEW acc  SET acc=$$ACCEPT(diff)
  . ; Assign next id and persist
  . SET last=last+1,cnt=cnt+1
  . DO PUTREC(last,title,slug,diff,tags,desc,acc)
  ;CLOSE FILE
  SET ^PROB("last")=last
  WRITE "Imported: ",cnt," (last id=",last,")",!
  QUIT
; ---------------------------
; Write a single record + indexes
; ---------------------------
PUTREC(id,title,slug,diff,tags,desc,acc)
  NEW i,tag,tl
  SET ^PROB(id,"id")=id
  SET ^PROB(id,"title")=title
  SET ^PROB(id,"slug")=slug
  SET ^PROB(id,"difficulty")=diff
  SET ^PROB(id,"tags")=tags
  SET ^PROB(id,"desc")=desc
  SET ^PROB(id,"accept")=acc

  ; indexes
  SET tl=$$LOW(title)
  SET ^PROBIDX("title",$e(tl,1,255),id)=""
  SET ^PROBIDX("diff",diff,id)=""
  FOR i=1:1:$L(tags,"^") SET tag=$P(tags,"^",i) QUIT:tag=""  SET ^PROBIDX("tag",tag,id)=""
  QUIT

; ---------------------------
; JSON decode placeholder
; ---------------------------
DECODE(JSON,ROOT) ; return 1 on success, 0 on failure
  KILL @ROOT
  ; === PLACEHOLDER: replace the next line with your JSON->global decoder ===
  ; Examples (choose ONE and adjust to your environment):
  ;   DO DECODE^%YDBJSON(.JSON,ROOT)            ; YottaDB example (if available)
  ;   SET ok=$$DECODE^%ZSJSON(.JSON,ROOT)       ; Custom JSON lib returning ok
  ;   DO JSONTOG^MYJSON(.JSON,ROOT) SET ok=1    ; Your routine fills @ROOT(...)
  NEW ok SET ok=0
  ; ------------------------------------------------------------
  ; !!! IMPLEMENT YOUR JSON DECODER HERE, set ok=1 on success !!!
  ; It must populate nodes like:
  ;   @ROOT@("task_id")="two-sum"
  ;   @ROOT@("meta","difficulty")="Easy"
  ;   @ROOT@("meta","question_title")="Two Sum"
  ; ------------------------------------------------------------
  n str s str(1)=JSON
  d decode^aajson($na(str),ROOT) s ok=1
  QUIT ok

; ---------------------------
; Safe access to decoded JSON tree
; PATH: caret-separated, e.g. "meta^difficulty"
; ---------------------------
VAL(ROOT,PATH)
  NEW ref SET ref=ROOT
  NEW i,sub
  FOR i=1:1:$L(PATH,"^") SET sub=$P(PATH,"^",i) QUIT:sub=""  SET ref=$NAME(@ref@(sub))
  QUIT $GET(@ref)

; ---------------------------
; Normalization helpers
; ---------------------------
NORMDIFF(d)
  NEW x SET x=$$LOW($GET(d))
  QUIT $SELECT(x="easy":"Easy",x="medium":"Medium",x="hard":"Hard",1:"Medium")

TITLECASE(slug)
  NEW out,i,part SET out=""
  FOR i=1:1:$L(slug,"-") SET part=$P(slug,"-",i) DO
  . IF part="" QUIT
  . SET out=out_$S(out'="":" ",1:"")_$ZCONVERT($E(part,1),"U")_$ZCONVERT($E(part,2,$L(part)),"L")
  QUIT out

; Heuristic tags from keywords in combined text
TAGS(text)
  NEW t SET t=$$LOW(text)
  NEW acc SET acc=""
  DO ADDTAG("array","array")
  DO ADDTAG("string","string")
  DO ADDTAG("tree","tree")
  DO ADDTAG("binary tree","tree")
  DO ADDTAG("graph","graph")
  DO ADDTAG("stack","stack")
  DO ADDTAG("queue","queue")
  DO ADDTAG("heap","heap")
  DO ADDTAG("hash","hash-table")
  DO ADDTAG("sliding window","sliding-window")
  DO ADDTAG("two pointers","two-pointers")
  DO ADDTAG("dynamic programming","dp")
  DO ADDTAG("backtrack","backtracking")
  DO ADDTAG("trie","trie")
  DO ADDTAG("greedy","greedy")
  QUIT acc
ADDTAG(needle,tag) NEW n SET n=$$LOW(needle) IF t[n SET acc=acc_$S(acc'="":"^",1:"")_tag QUIT
 Q

; Acceptance rate by difficulty with slight jitter for realism
ACCEPT(diff)
  NEW base SET base=$S(diff="Easy":70,diff="Medium":50,1:32)
  NEW j SET j=$R(600)-300  ; -3.00..+2.99
  QUIT (base*100+j)/100

; ---------------------------
; Error & I/O
; ---------------------------
OPENERR WRITE "Cannot open file: ",$GET(FILE),!,! QUIT
ERR WRITE "Error: ",$ZSTATUS,!,! QUIT
LOW(S) Q $ZCONVERT(S,"L")