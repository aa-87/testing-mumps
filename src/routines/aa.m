aa ;
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
 	s aa("aa")="debug^aa"
 	s aa("ping")="ping^aa"
 	s aa("api/problems/")="ping^aa"
 	s aa("api/problems/:idOrSlug")="ping^aa"
 	s aa("api/problems/facet")="ping^aa"
 	q
ping(i,o)
	s ^PING=($I(^PING))=i
	s o="pong"
	q
debug(q,r,z)
	s r("mime")="text/html"
	n i,c s c=0 s i="" f  s i=$o(q(i)) q:i=""  s c=c+1,r(c)=i_" = "_q(i)_"<br>"
	q
run(q,r,z)
	s r("mime")="text/html"
	s r(1)="running..."
	q
ws  s $et="s ^E=$zstatus"
  	u %io:(nodelim)
  	w "HTTP/1.1 101 Switching Protocols"_$C(13,10)
  	w "Upgrade: websocket"_$C(13,10)
  	w "Connection: Upgrade"_$C(13,10)
	w "Sec-WebSocket-Accept: "
	w $$genws(q("header","sec-websocket-key"))
	w $C(13,10)_$C(13,10) 
ws1	
	k x,y,z,msk,pz,i,pl,opc r *x s opc=x r *x s x=x-128 i x<=125 s pz=x
	s ^OP($i(^OP))=opc
	i opc=136 w $$wsmsg("") h
	i x=126 r x#2 s pz=$$wssz16(x)
	i x=127 r x#8 s pz=$$wssz64(x)
	r msk#4 r pl#pz
	k %wsi,%wso s (%wsi,%wso)=""
	s %wsi=$$unmsk(pl,msk) k rtn,z s (rtn,z)="" d m(.rtn,.z)
	d @(rtn_"(%wsi,.%wso)")
	w $$wsmsg(%wso)
	h 0.01 g ws1
wsmsg(m,opcode)
	 n b1,b2,len,o s o="" i $g(opcode)="" s opcode=1
	 s b1=$s(1:128,1:0) ; FIN=1 -> only -> single-frame messages		
	 S b1=b1+opcode     ; 8=close   9=ping   10=pong    1=text
 	 s len=$l($g(m))
 	 i len<126 s b2=len s o=o_$C(b1,b2)
 	 i len>=126,len<65536126 s b2=126 s o=o_$C(b1,b2)_$C(len\256#256,len#256)
	 i len>=65536126 d
	 . s b2=127
	 . n i,buf s buf=""
	 . n l s l=len
	 . f i=7:-1:0 s buf=$c((l\(256**i))#256)_buf
	 . s o=o_$C(b1,b2)_buf
	 q o_m
	;
err s ^aa("err")=$zstatus q	
Start(p) k (p) i '$g(p) s p=7777 i 1
	j job(p) h 0.1 i '$t w !,"failed to start" q
	w "aa started"_$c(10)_"pid: " s ^aa("pid")=$zj w ^aa("pid") q
Stop i $g(^aa("pid")) zsy "kill "_^aa("pid") i 1
	e  w "no pid in ^aa(""pid"")" q
	w !,"killed pid: "_^aa("pid")_$c(10)_"stopped",! q
job(p) s $et="g err^aa" 
 	s t="SCK$"_p o t:(LISTEN=p_":TCP":delim=$C(13,10):attach="server":chset="M"):15:"socket"
	e  s ^aa("err_startup")="cannot open port "_p q
	u t:(chset="M") w /LISTEN(5) n ps,cs s ps=$p($KEY,"|",2)
lp  d  g lp
	. f  w /WAIT q:$KEY]""
	. i $p($KEY,"|")="CONNECT" s cs=$P($KEY,"|",2)  u t:(detach=cs) d 
	. . n q,z,j s q="""",z=q_"SOCKET:"_cs_q,j="lp1:(input="_z_":output="_z_")"
	. . j @j
lp1e c %io g err
lp3e d err c %p h
lp1 n %io s %io=$P n $et s $et="g lp1e^%aa"
lp2 k q,r,err
lp3 u %io:(delim=$C(13,10):chset="M") r tcpx:10 i '$t g err
	i '$l(tcpx) g lp3e
	s q("method")=$p(tcpx," "),q("path")=$P($P(tcpx," ",2),"?")
	s q("query")=$P($P(tcpx," ",2),"?",2,999) k %b
	i $e($p(tcpx," ",3),1,4)'="HTTP" g lp2
	f  s tcpx=$$line() q:'$l(tcpx)  d hd(tcpx)
	i $g(q("header","expect"))="100-continue" w "HTTP/1.1 100 Continue",$C(13,10,13,10),!
	i $zconvert($g(q("header","connection")),"l")="upgrade",$zconvert($g(q("header","upgrade")),"l")="websocket" g ws
	u %io:(nodelim) i $g(q("header","content-length")) d rl(q("header","content-length"))
	s $et="g srvr500^aa",err=0 d rsp s $et="g lp1e^aa" u %io:(nodelim:chset="M") d sd c %io h
line() n x,line,retry s line="" f retry=1:1 r x:1 s line=line_x q:$a($zb)=13  q:retry>10
	q line
rl(rmn) n x,line,len s line=0
rdlp s len=rmn i len>1000000 s len=1000000 r x#len:10 i '$t s line=line+1,%b(line)=x q
	s rmn=rmn-$l(x),line=line+1,%b(line)=x
	g:rmn rdlp
	q
hd(line)
	n name,value s name=$zconvert($$ltrim($P(line,":")),"l"),value=$$ltrim($P(line,":",2,99))
	i line'[":" s name="",value=line
	i '$l(name) s name=$g(q("header")) i '$l(name) q
	i $d(q("header",name)) s q("header",name)=q("header",name)_","_value i 1
	e  s q("header",name)=value,q("header")=name
	q
socketerr d err c %io h
srvr500 S $et="g srvr500et^aa" d err
	d sd s $et="q:$ESTACK&$QUIT 0 q:$ESTACK  s $ECODE="""" g lp2"
	q
srvr500et d err u %io w "HTTP/1.1 500 Internal Server Error-",$C(13,10),$C(13,10),! c %io h
ltrim(x) n l,z s l=1,z=$l(x) f l=1:1:z q:$a($e(x,l))>32
	q $e(x,l,z)
rsp n rtn,loc,z,%b s rtn=""
	d m(.rtn,.z) I $g(err) q
	d rsp1(.z) I $g(err) q
	k r d @(rtn_"(.q,.r,.z)")
	q
rsp1(qry) n i,x,name,value
	f i=1:1:$l(q("query"),"&") d
	. s x=$$urldec($p(q("query"),"&",i))
	. s name=$p(x,"="),value=$p(x,"=",2,$l(x,"="))
	. i $l(name) s qry($zconvert(name,"l"))=value
	q
m(rtn,args) n aud s rtn="" d mf(.rtn,.args,.aud) Q
mf(rtn,args,aud) n p S p=q("path") s:$e(p)="/" p=$e(p,2,$l(p))
	n dn s dn=0 n p1 s p1=$$urldec($p(p,"/",1,9999),1) 
	n p1 s p1=$$urldec($P(p,"/",1),1)
	n ptrn s ptrn=p1 i ptrn="" s ptrn="/"
	d mf2(.rtn,.args,.aud)
	q
mf2(rtn,args,aud) n p s p=q("path") s:$e(p)="/" p=$e(p,2,$l(p))
	n dn s dn=0 n p1 s p1=$$urldec($p(p,"/",1),1)
	n ptn s ptn=p1 i ptn="" S ptn="/"
	i ptn=""  s ptn="aa"
	i ptn="/" s ptn="aa"
	d main i $d(aa(ptn)) s rtn=aa(ptn) i 1
	e  s rtn="run"
	q
sd  n %wb s %wb="" n size,rstyp,prm,strt,lmt s size=$$vrz(.r) d w($$rspline()_$C(13,10))
	i $d(q("Content-Disposition")) d w("Content-Disposition: "_q("Content-Disposition")_$C(13,10))
	i $d(q("x-Accel-Redirect")) d w("x-Accel-Redirect: "_q("x-Accel-Redirect")_$C(13,10))
	i $d(q("set_cookie")) d w("Set-Cookie: "_q("set_cookie")_$C(13,10))
	i $d(q("location")) d w("Location: "_q("location")_$C(13,10))
	i $d(r("auth")) d w("WWW-Authenticate: "_r("auth")_$C(13,10)) k r("auth")
	i $d(r("mime")) d w("Content-Type: "_r("mime")_$C(13,10)) k r("mime") i 1
	e  d w("Content-Type: application/json; charset=utf-8"_$C(13,10))
	d w("Content-Length: "_size_$C(13,10)_$C(13,10))
	I 'size d flsh Q
	n i s i=0 f  s i=$o(r(i)) q:'i  d w(r(i))
	d flsh
	q
w(d) i ($l(%wb)+$l(d))>1000000 d flsh
	s %wb=%wb_d
	q
flsh w %wb s %wb="" q
rspline()
	i '$G(err),'$d(q("location")) q "HTTP/1.1 200 OK"
	i '$G(err),$d(q("location")) q "HTTP/1.1 201 Created"
	i $G(err)=400 q "HTTP/1.1 400 Bad Request"
	i $G(err)=401 q "HTTP/1.1 401 Unauthorized"
	i $G(err)=404 q "HTTP/1.1 404 Not Found"
	i $G(err)=405 q "HTTP/1.1 405 Method Not Allowed"
	i $G(err)=302 q "HTTP/1.1 302 Moved Temporarily"
	q "HTTP/1.1 500 Internal Server Error"
urldec(x,p) n i,out,frag,asc s:'$g(p) x=$tr(x,"+"," ") f i=1:1:$l(x,"%") d
	. i i=1 s out=$p(x,"%") q
	. s frag=$P(x,"%",i),asc=$e(frag,1,2),frag=$e(frag,3,$l(frag))
	. i $l(asc) s out=out_$c($zconvert(out,"HEX","DEC"))
	. s out=out_frag
	q out
vrz(v)
	n i,size s i="",size=0 f  s i=$O(v(i)) q:'i  s size=size+$l(v(i))
	q size
sha1(x) n d,c,s,o,cd s d="shasum"_$j,c="echo -n """_x_""" | openssl sha1 -binary | openssl base64"
 	s o="",cd=$p o d:(shell="/bin/sh":comm=c)::"pipe" u d f  q:$zeof=1  r s:2 s o=o_$p(s," ") q:'$t
 	c d u cd q o
genws(k) n t s t="258EAFA5-E914-47DA-95CA-C5AB0DC85B11" q $$sha1(k_t)
unmsk(x,y) n i,o s o="" f i=1:1:$l(x) s o=o_$c($$xor($a(x,i),$a(y,$s('(i#4):4,1:i#4)),8))
	q o
xor(a,b,w) n i,m,r s r=b,m=1 f i=1:1:w s:a\m#2 r=r+$s(r\m#2:-m,1:m) s m=m+m
	q r	
wssz64(x) n x1,x2,x3,x4,x5,x6,x7,x8 s x1=$a($e(x)),x2=$a($e(x,2)),x3=$a($e(x,3)),x4=$a($e(x,4))
 	s x5=$a($e(x,5)),x6=$a($e(x,6)),x7=$a($e(x,7)),x8=$a($e(x,8))
 	q (x1*256**7)+(x2*256**6)+(x3*256**5)+(x4*256**4)+(x5*256**3)+(x6*256**2)+(x7*256)+x8	
wssz16(x) n x1,x2 s x1=$a($e(x)),x2=$a($e(x,2)) q (x1*256)+x2