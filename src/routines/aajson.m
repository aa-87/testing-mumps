aajson
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
encode(aaroot,aajson,aaerr)
	i '$l($g(aaroot)) q
	i '$l($g(aajson)) q
	n aaline,aamax,aaerrors
	s aaline=1,aamax=1000000,aaerrors=0
	s @aajson@(aaline)=""
	d serobj(aaroot)
	q
decode(aajson,aaroot,aaerr)
	n aamax s aamax=1000000
	i $d(@aajson)=1 n aainput s aainput(1)=@aajson,aajson="aainput"
	s aaroot=$na(@aaroot@("z")),aaroot=$e(aaroot,1,$l(aaroot)-4)
	n aaline,aaidx,aastack,aaprop,aatype,aaerrors
	s aaline=$o(@aajson@("")),aaidx=1,aastack=0,aaprop=0,aaerrors=0
	f  s aatype=$$nxtkn() q:aatype=""  d  i aaerrors q
	. i aatype="{" s aastack=aastack+1,aastack(aastack)="",aaprop=1 d:aastack>64 errx("stl{") q
	. i aatype="}" d:$$numeric(aastack(aastack)) errx("obm") s aastack=aastack-1 d:aastack<0 errx("suf}") q
	. i aatype="[" s aastack=aastack+1,aastack(aastack)=1 d:aastack>64 errx("stl[") q
	. i aatype="]" d:'$$numeric(aastack(aastack)) errx("arm") s aastack=aastack-1 d:aastack<0 errx("suf]") q
	. i aatype="," d  q
	. . i aastack(aastack) s aastack(aastack)=aastack(aastack)+1 
	. . e  s aaprop=1 
	. i aatype=":" s aaprop=0 d:'$l($g(aastack(aastack))) errx("mpn") q
	. i aatype="""" d  q
	. . i aaprop s aastack(aastack)=$$nampars() i 1
	. . e  d addstr
	. s aatype=$tr(aatype,"tfn","tfn")
	. i aatype="t"  d  q
	. . i $l(@aajson@(aaline))<=aaidx+2,$d(@aajson@(aaline+1)) d
	. . . s @aajson@(aaline)=@aajson@(aaline)_$e(@aajson@(aaline+1),1,2),@aajson@(aaline+1)=$e(@aajson@(aaline+1),3,$l(@aajson@(aaline+1)))
	. . i $tr($e(@aajson@(aaline),aaidx,aaidx+2),"rue","rue")="rue" d setbool("true") i 1
	. . e  b  d errx("ext",aatype)
	. i aatype="f" d  q
	. . i $l(@aajson@(aaline))<=aaidx+3,$d(@aajson@(aaline+1)) d
	. . . s @aajson@(aaline)=@aajson@(aaline)_$e(@aajson@(aaline+1),1,3),@aajson@(aaline+1)=$e(@aajson@(aaline+1),4,$l(@aajson@(aaline+1)))
	. . i $tr($e(@aajson@(aaline),aaidx,aaidx+3),"alse","alse")="alse" d setbool("false") i 1
	. . e  d errx("exf",aatype)
	. i aatype="n" d  q
	. . i $l(@aajson@(aaline))<=aaidx+2,$d(@aajson@(aaline+1)) d
	. . . s @aajson@(aaline)=@aajson@(aaline)_$e(@aajson@(aaline+1),1,2),@aajson@(aaline+1)=$e(@aajson@(aaline+1),3,$l(@aajson@(aaline+1)))
	. . i $tr($e(@aajson@(aaline),aaidx,aaidx+2),"ull","ull")="ull" d setbool("null") i 1
	. . e  d errx("exn",aatype)
	. i "0123456789+-.ee"[aatype s @$$curnode()=$$numpars(aatype) q
	. d errx("tkn",aatype_"["_$e(@aajson@(aaline),aaidx,aaidx+2)_"] ")
	i aastack'=0 d errx("sct",aastack)
	q
errx(id,val)
	n errmsg
	i id="stl{" s errmsg="stack too large for new object." g xerrx
	i id="suf}" s errmsg="stack underflow - extra } found" g xerrx
	i id="stl[" s errmsg="stack too large for new array." g xerrx
	i id="suf]" s errmsg="stack underflow - extra ] found." g xerrx
	i id="obm" s errmsg="array missmatch - expected ] got }." g xerrx
	i id="arm" s errmsg="object mismatch - expected } got ]." g xerrx
	i id="mpn" s errmsg="missing property name." g xerrx
	i id="ext" s errmsg="expected true, got "_val g xerrx
	i id="exf" s errmsg="expected false, got "_val g xerrx
	i id="exn" s errmsg="expected null, got "_val g xerrx
	i id="tkn" s errmsg="unable to identify type of token, value was "_val g xerrx
	i id="sct" s errmsg="stack mismatch - exit stack level was  "_val g xerrx
	i id="eiq" s errmsg="close quote not found before end of input." g xerrx
	i id="eiu" s errmsg="unexpected end of input while unescaping." g xerrx
	i id="rsb" s errmsg="reverse search for \ past beginning of input." g xerrx
	i id="orn" s errmsg="overrun while scanning name." g xerrx
	i id="or#" s errmsg="overrun while scanning number." g xerrx
	i id="orb" s errmsg="overrun while scanning boolean." g xerrx
	i id="esc" s errmsg="escaped character not recognized"_val g xerrx
	i id="sob" s errmsg="unable to serialize node as object, value was "_val g xerrx
	i id="sar" s errmsg="unable to serialize node as array, value was "_val g xerrx
	s errmsg="unspecified error "_id_" "_$g(val)
xerrx
	s @aaerr@(0)=$g(@aaerr@(0))+1
	s @aaerr@(@aaerr@(0))=errmsg
	s aaerrors=aaerrors+1
	q
nxtkn()
	n aadn,aaeof,aatoken
	s aadn=0,aaeof=0 f  d  q:aadn!aaeof
	. i aaidx>$l(@aajson@(aaline)) s aaline=$o(@aajson@(aaline)),aaidx=1 i 'aaline s aaeof=1 q
	. i $a(@aajson@(aaline),aaidx)>32 s aadn=1 q
	. s aaidx=aaidx+1
	q:aaeof ""
	s aatoken=$e(@aajson@(aaline),aaidx),aaidx=aaidx+1
	q aatoken
addstr
	n aaend,aax
	s aaend=$f(@aajson@(aaline),"""",aaidx)
	i aaend,($e(@aajson@(aaline),aaend-2)'="\") d setstr  q
	i aaend,$$iscloseq(aaline) d setstr q
	n aadn,aatline
	s aadn=0,aatline=aaline
	f  d  q:aadn  q:aaerrors
	. i 'aaend s aatline=aatline+1,aaend=1 i '$d(@aajson@(aatline)) d errx("eiq") q
	. s aaend=$f(@aajson@(aatline),"""",aaend)
	. i aaend,$e(@aajson@(aatline),aaend-2)'="\" s aadn=1 q
	. s aadn=$$iscloseq(aatline)
	q:aaerrors
	d uesext
	s aaline=aatline,aaidx=aaend
	q
setstr
	n aax
	s aax=$e(@aajson@(aaline),aaidx,aaend-2),aaidx=aaend
	s @$$curnode()=$$ues(aax)
	i aaidx>$l(@aajson@(aaline)) s aaline=aaline+1,aaidx=1
	q
uesext
	n aai,aay,aastart,aastop,aadn,aabuf,aanode,aamore,aato
	s aanode=$$curnode(),aabuf="",aamore=0,aastop=aaend-2
	s aai=aaidx,aay=aaline,aadn=0
	f  d  q:aadn  q:aaerrors
	. s aastart=aai,aai=$f(@aajson@(aay),"\",aai)
	. i (aay=aatline) s aato=$s('aai:aastop,aai>aastop:aastop,1:aai-2) i 1
	. e  s aato=$s('aai:99999,1:aai-2)
	. d addbuf($e(@aajson@(aay),aastart,aato))
	. i (aay'<aatline),(('aai)!(aai>aastop)) s aadn=1 quit
	. i 'aai s aay=aay+1,aai=1 quit 
	. i aai>$l(@aajson@(aay)) s aay=aay+1,aai=1 i '$d(@aajson@(aay)) d errx("eiu")
	. d addbuf($$realchar($e(@aajson@(aay),aai),@aajson@(aay),.aai))
	. s aai=aai+1
	. i (aay'<aatline),(aai>aastop) s aadn=1
	q:aaerrors
	d savebuf
	q
addbuf(aax)
	i $l(aax)+$l(aabuf)>aamax d savebuf
	s aabuf=aabuf_aax
	q
savebuf
	i 'aamore s @aanode=aabuf s:+aabuf=aabuf @aanode@("\s")="" i 1
	e  s @aanode@("\",aamore)=aabuf
	s aamore=aamore+1,aabuf=""
	q
iscloseq(aabline)
	n aaback,aabidx
	s aaback=0,aabidx=aaend-2
	f  d  q:$e(@aajson@(aabline),aabidx)'="\"  q:aaerrors
	. s aaback=aaback+1,aabidx=aabidx-1
	. i (aabline=aaline),(aabidx=aaidx) q
	. q:aabidx
	. s aabline=aabline-1 i aabline<aaline d errx("rsb") q
	. s aabidx=$l(@aajson@(aabline))
	q aaback#2=0
nampars()
	n aaend,aadn,aaname
	s aadn=0,aaname=""
	f  d  q:aadn  q:aaerrors
	. s aaend=$f(@aajson@(aaline),"""",aaidx)
	. i aaend s aaname=aaname_$e(@aajson@(aaline),aaidx,aaend-2),aaidx=aaend,aadn=1
	. i 'aaend s aaname=aaname_$e(@aajson@(aaline),aaidx,$l(@aajson@(aaline)))
	. i 'aaend!(aaend>$l(@aajson@(aaline))) s aaline=aaline+1,aaidx=1 i '$d(@aajson@(aaline)) d errx("orn")
	q aaname
numpars(aadigit)
	n aadn,aanum
	s aadn=0,aanum=aadigit
	f  d  q:aadn  q:aaerrors
	. i '("0123456789+-.ee"[$e(@aajson@(aaline),aaidx)) s aadn=1 q
	. s aanum=aanum_$e(@aajson@(aaline),aaidx)
	. s aaidx=aaidx+1 i aaidx>$l(@aajson@(aaline)) s aaline=aaline+1,aaidx=1 i '$d(@aajson@(aaline)) d errx("or#")
	q aanum
setbool(aax)
	s @$$curnode()=aax
	s aaidx=aaidx+$l(aax)-1
	n aadiff s aadiff=aaidx-$l(@aajson@(aaline))
	i aadiff>0 s aaline=aaline+1,aaidx=aadiff i '$d(@aajson@(aaline)) d errx("orb")
	q
curnode()
	n aai,aasubs
	s aasubs=""
	f aai=1:1:aastack s:aai>1 aasubs=aasubs_"," d
	. i $$numeric(aastack(aai))  s aasubs=aasubs_aastack(aai)
	. e  s aasubs=aasubs_""""_aastack(aai)_""""
	q aaroot_aasubs_")"
ues(x)
	n pos,y,strt
	s pos=0,y=""
	f  s strt=pos+1 d  q:strt>$l(x)
	. s pos=$f(x,"\",pos+1)
	. i 'pos s y=y_$e(x,strt,$l(x)),pos=$l(x) i 1
	. e  s y=y_$e(x,strt,pos-2)_$$realchar($e(x,pos),x,.pos)
	q y
realchar(c,x,pos)
	n opos
	i c="""" q """"
	i c="/" q "/"
	i c="\" q "\"
	i c="b" q $c(8)
	i c="f" q $c(12)
	i c="n" q $c(10)
	i c="r" q $c(13)
	i c="t" q $c(9)
	i c="u" s opos=pos s pos=pos+4 q $c($$FUNC^%HD($e(x,opos+1,opos+4)))
	q c
replace(s,f,t)
	i $tr(s,f)=s q s
	n o,i s o="" f i=1:1:$l(s,f)  s o=o_$s(i<$l(s,f):$p(s,f,i)_t,1:$p(s,f,i))
	q o
serobj(aaroot)
	n aafirst,aasub,aanxt
	s @aajson@(aaline)=@aajson@(aaline)_"{"
	s aafirst=1
	s aasub="" f  s aasub=$o(@aaroot@(aasub)) q:aasub=""  d
	. s:'aafirst @aajson@(aaline)=@aajson@(aaline)_"," s aafirst=0
	. d sername(aasub)
	. i $$isvalue(aaroot,aasub) d serval(aaroot,aasub) q
	. i $d(@aaroot@(aasub))=10 s aanxt=$o(@aaroot@(aasub,"")) d  q
	. . i +aanxt d serary($na(@aaroot@(aasub))) i 1
	. . e  d serobj($na(@aaroot@(aasub)))
	. d errx("sob",aasub)
	s @aajson@(aaline)=@aajson@(aaline)_"}"
	q
serary(aaroot)
	n aafirst,aai,aanxt
	s @aajson@(aaline)=@aajson@(aaline)_"["
	s aafirst=1
	s aai=0 f  s aai=$o(@aaroot@(aai)) q:'aai  d
	. s:'aafirst @aajson@(aaline)=@aajson@(aaline)_"," s aafirst=0
	. i $$isvalue(aaroot,aai) d serval(aaroot,aai) q 
	. i $d(@aaroot@(aai))=10 s aanxt=$o(@aaroot@(aai,"")) d  q
	. . i +aanxt d serary($na(@aaroot@(aai))) i 1
	. . e  d serobj($na(@aaroot@(aai)))
	. d errx("sar",aai)
	s @aajson@(aaline)=@aajson@(aaline)_"]"
	q
sername(aasub)
	i ($l(aasub)+$l(@aajson@(aaline)))>aamax s aaline=aaline+1,@aajson@(aaline)=""
	s @aajson@(aaline)=@aajson@(aaline)_""""_aasub_""""_":"
	q
serval(aaroot,aasub)
	n aax,aai
	i $d(@aaroot@(aasub,":")) d  q
	. s aax=$g(@aaroot@(aasub,":")) d:$l(aax) concat
	. s aai=0 f  s aai=$o(@aaroot@(aasub,":",aai)) q:'aai  s aax=@aaroot@(aasub,":",aai) d concat
	s aax=$g(@aaroot@(aasub))
	i '$d(@aaroot@(aasub,"\s")),$$numeric(aax) d concat quit
	i (aax="true")!(aax="false")!(aax="null") d concat quit
	s aax=""""_$$esc(aax)
	d concat
	i $d(@aaroot@(aasub,"\")) d
	. s aai=0 f  s aai=$o(@aaroot@(aasub,"\",aai)) q:'aai   d
	. . s aax=$$esc(@aaroot@(aasub,"\",aai))
	. . d concat
	s aax="""" d concat
	q
concat
	i ($l(aax)+$l(@aajson@(aaline)))>aamax s aaline=aaline+1,@aajson@(aaline)=""
	s @aajson@(aaline)=@aajson@(aaline)_aax
	q
isvalue(aaroot,aasub)
	i $d(@aaroot@(aasub))#2 q 1
	n aax s aax=$o(@aaroot@(aasub,""))
	q:aax="\" 1
	q:aax=":" 1
	q 0
numeric(x) 
	i $l(x,".")>2 q 0
	i $e(x,1,2)="-." q 0
	i x=+x,$l(x)'=$l(+x) q 0
	i $e(x)="." q 0
	i x=+x q 1
	q 0
esc(x)
	n y,%DH
	s y=x
	i x["\"  s y=$$replace(y,"\","\\")
	i x["""" s y=$$replace(y,"""","\""")
	i x["/"  s y=$$replace(y,"/","\/")
	i x[$c(8) s y=$$replace(y,$c(8),"\"_$c(98))
	i x[$c(12) s y=$$replace(y,$c(12),"\"_$c(102))
	i x[$c(10) s y=$$replace(y,$c(10),"\"_$c(110))
	i x[$c(13) s y=$$replace(y,$c(13),"\"_$c(114))
	i x[$c(9) s y=$$replace(y,$c(9),"\"_$c(116))
	n i f i=1:1:$l(x) d
	. i $a($e(x,i))=8   q 
	. i $a($e(x,i))=12  q 
	. i $a($e(x,i))=10  q 
	. i $a($e(x,i))=13  q 
	. i $a($e(x,i))=9   q 
	. i $a($e(x,i))>=33 q
	. s %DH=$a($e(x,i))
	. d ^%DH
	. s y=$$replace(y,$e(x,i),"\u"_$e(%DH,$l(%DH)-3,$l(%DH)))
	q y 