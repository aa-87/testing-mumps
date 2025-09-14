WS ; Simple WebSocket server helpers for GT.M/YottaDB
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

 ; ==== HTTP -> WebSocket upgrade ====
WSHAND(sock) ; sock is your already-accepted TCP socket descriptor
 N hdr,line,key,accept,proto,origin,ok S ok=1
 K hdr S key="",proto="",origin=""
 ; Read HTTP headers (terminated by blank line)
 F  D  Q:line=""
 . U sock R line Q:$ZEOF
 . S line=$ZSTRIP(line,"<>W") Q:line=""
 . N name,val S name=$$LOWER^%ZFUNC($P(line,":",1)),val=$$TRIM($P(line,":",2,999))
 . S hdr(name)=val
 . I name="sec-websocket-key" S key=$$TRIM(val)
 . I name="sec-websocket-protocol" S proto=$$TRIM(val)
 . I name="origin" S origin=$$TRIM(val)
 I $G(hdr("upgrade"))'="websocket" S ok=0
 I $G(hdr("connection"))'["Upgrade" S ok=0
 I $G(hdr("sec-websocket-version"))'="13" S ok=0
 I key="" S ok=0

 ; Optional: allow-list origin
 ; I origin'["http://localhost:5173",origin'["https://yourdomain" S ok=0

 I 'ok D  Q
 . U sock W "HTTP/1.1 400 Bad Request",!,"Content-Length: 0",!,! Q

 ; Compute Sec-WebSocket-Accept
 N GUID S GUID="258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
 N hashbin S hashbin=$$WSSHA1(key_GUID) ; raw binary bytes
 N accept64 S accept64=$$WSB64(hashbin)

 ; Optional subprotocol filter
 N respProto S respProto=""
 I proto["mumps.judge.v1" S respProto="Sec-WebSocket-Protocol: mumps.judge.v1"_$C(13,10)

 ; Send upgrade response
 U sock W "HTTP/1.1 101 Switching Protocols",!
 U sock W "Upgrade: websocket",!
 U sock W "Connection: Upgrade",!
 U sock W "Sec-WebSocket-Accept: "_accept64,!
 I respProto'="" U sock W respProto
 U sock W ! ; end of headers

 ; enter frame loop
 D WSLOOP(sock)
 Q

 ; ==== Main frame loop ====
WSLOOP(sock)
 N alive,lastpong,lastping S alive=1,lastpong=$H,lastping=$H
 F  Q:'alive  D  H 0.01
 . N opcode,payload,fin,err S err=0
 . D WSREAD(sock,.opcode,.payload,.fin,.err)
 . I err S alive=0 Q
 . ; Handle opcodes
 . I opcode=8 D  Q  ; Close
 . . ; Echo a close
 . . D WSSEND(sock,8,"") S alive=0
 . E  I opcode=9 D  Q  ; Ping -> Pong
 . . D WSSEND(sock,10,payload)
 . E  I opcode=10 S lastpong=$H Q  ; Pong
 . E  I opcode=1 D  ; Text
 . . D DISPATCH(sock,payload)
 . ; Keepalive every ~30s
 . I $$ELAPSED(lastping)>30 D WSSEND(sock,9,"ping"),S lastping=$H
 . ; Drop if no pong for 90s
 . I $$ELAPSED(lastpong)>90 S alive=0
 ; ensure socket closes
 C sock
 Q

ELAPSED(ts) ; seconds since $H timestamp
 N s1,s2,s3 S s1=$P($H,",",1),s2=$P($H,",",2),s3=$P(ts,",",1)
 Q (s1-s3)*86400+($P($H,",",2)-$P(ts,",",2))

 ; ==== Frame parsing (client->server are masked) ====
WSREAD(sock,opcode,payload,fin,err)
 N b1,b2,len,mask,ext,maskkey,i,byte
 S (opcode,payload,fin,err)="",len=0,mask=0,ext=0
 ; read first 2 bytes
 U sock R *b1:*5 I '$T S err=1 Q
 U sock R *b2:*5 I '$T S err=1 Q
 S fin=(b1\128),opcode=(b1#128)
 S mask=(b2\128),len=(b2#128)
 I len=126 D  I err Q
 . N x1,x2 U sock R *x1,*x2:*5 I '$T S err=1 Q
 . S len=(x1*256)+x2
 I len=127 D  I err Q
 . N i,b S len=0
 . F i=1:1:8 U sock R *b:*5 I '$T S err=1 Q  S len=(len*256)+b
 . I err Q
 I mask D  I err Q
 . N k U sock R *k(1),*k(2),*k(3),*k(4):*5 I '$T S err=1 Q
 . S maskkey=$C(k(1))_$C(k(2))_$C(k(3))_$C(k(4))
 ; read payload
 I len>0 U sock R payload#len:*10 I '$T S err=1 Q
 ; unmask
 I mask D
 . N out S out=""
 . F i=1:1:$L(payload) D
 . . N mk,pi,mi
 . . S pi=$A(payload,i),mi=$A(maskkey,((i-1)#4)+1)
 . . S out=out_$C(pi#256 Xor mi)
 . S payload=out
 Q

 ; ==== Frame builder (server->client usually unmasked) ====
WSSEND(sock,opcode,payload)
 N b1,b2,len
 S b1=$S(1:128,1:0) ; FIN=1 only for single-frame messages
 S b1=b1+opcode
 S len=$L($G(payload))
 I len<126 S b2=len U sock W $C(b1,b2)
 E  I len<65536 S b2=126 U sock W $C(b1,b2)_$C(len\256#256,len#256)
 E  D
 . S b2=127
 . N i,buf S buf=""
 . N L S L=len
 . F i=7:-1:0 S buf=$C((L\(256**i))#256)_buf
 . U sock W $C(b1,b2)_buf
 I len>0 U sock W $G(payload)
 Q

 ; ==== Minimal dispatch: expect JSON text messages ====
DISPATCH(sock,json)
 N cmd S cmd=$$GETVAL(json,"type")
 I cmd="ping" D WSSEND(sock,1,"{""type"":""pong""}") Q
 I cmd="run" D JUDGE(sock,json) Q
 ; default echo
 D WSSEND(sock,1,"{""type"":""echo"",""data"": "_$$ESC(json)_"}")
 Q

 ; ==== Judge stub (see section 4) ====
JUDGE(sock,json)
 N code,problem S code=$$GETVAL(json,"code"),problem=$$GETVAL(json,"problemId")
 ; Here you’d enqueue/run in a child process; for MVP we’ll just fake result:
 D WSSEND(sock,1,"{""type"":""result"",""status"":""ok"",""passed"":true,""tests"":3}")
 Q

 ; ==== Helpers: JSON mini-get (MVP, naive) ====
GETVAL(s,key)
 N p,sub S p=$F(s,""""_key_"""")
 I 'p Q ""
 S p=$F(s,":",p),sub=$E(s,p,$L(s))
 N q,delim S delim=$E(sub,1)
 I delim="""" D  Q $E(sub,2,q-1)
 . S q=$F(sub,"""",2)
 E  D  Q $E(sub,1,q-1)
 . S q=$F(sub,",")
 . I 'q S q=$F(sub,"}")
 Q ""

ESC(x) ; escape quotes for JSON
 N i,out S out="" F i=1:1:$L(x) S out=out_$S($E(x,i)="""":"""""",1:$E(x,i))
 Q """"_out_""""

TRIM(s) Q $$LTRIM($$RTRIM(s))
LTRIM(s) F  Q:$E(s)'=" "  S s=$E(s,2,$L(s)) Q
 Q s
RTRIM(s) F  Q:$E(s,$L(s))'=" "  S s=$E(s,1,$L(s)-1) Q
 Q s

 ; ==== Crypto helpers via openssl ====
WSSHA1(str) ; returns raw binary of SHA1(str)
 N tmpin,tmpout,cmd,rc,bin
 S tmpin="/tmp/wsin."_$$PID() S tmpout="/tmp/wsout."_$$PID()
 O tmpin:(NEWVERSION:STREAM:WRITEONLY)
 U tmpin W str
 C tmpin
 S cmd="openssl dgst -sha1 -binary "_tmpin_" > "_tmpout
 S rc=$ZF(-1,cmd)
 O tmpout:(READONLY:STREAM)
 U tmpout R bin#999999
 C tmpout
 ZSYSTEM "rm -f "_tmpin_" "_tmpout
 Q bin

WSB64(bin) ; base64 of binary, via openssl
 N tmpin,tmpout,cmd,rc,b64
 S tmpin="/tmp/wsb64in."_$$PID() S tmpout="/tmp/wsb64out."_$$PID()
 O tmpin:(NEWVERSION:STREAM:WRITEONLY)
 U tmpin W bin
 C tmpin
 S cmd="openssl base64 -A < "_tmpin_" > "_tmpout
 S rc=$ZF(-1,cmd)
 O tmpout:(READONLY:STREAM)
 U tmpout R b64#999999
 C tmpout
 ZSYSTEM "rm -f "_tmpin_" "_tmpout
 Q b64

PID() Q $J  ; good enough for tmp naming on MVP