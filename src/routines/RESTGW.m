RESTGW ; Generic REST router for /api/resets/*
  QUIT
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
; Entry point your web server calls:
;   D DISPATCH^RESTGW(verb,path,body,.headers,.httpStatus,.payload)
DISPATCH(verb,path,body,headers,httpStatus,payload)
  NEW IN,OUT,seg1,seg2,seg3 S (httpStatus,payload)=""
  ; Require POST
  I $ZCONVERT($G(verb),"L")'="post" D RESP(.OUT,405,"method_not_allowed") G OUT

  ; Decode JSON body -> IN("...")  (replace with your JSON decoder)
  ; e.g. DO DECODE^JSON(.IN,body)  or  DO DECODE^YOURJSON(.IN,body)
  DO DECODE^JSON(.IN,body) ; <-- placeholder: use your decoder

  ; Split path: /api/resets/<action>
  S seg1=$P(path,"/",2),seg2=$P(path,"/",3),seg3=$P(path,"/",4)
  I seg1'="api"!(seg2'="resets") D RESP(.OUT,404,"not_found") G OUT

  ; Route
  I seg3="create"     DO CREATE^RESETSAPI(.IN,.OUT)
  E  I seg3="get"     DO GET^RESETSAPI(.IN,.OUT)
  E  I seg3="mark-used" DO USED^RESETSAPI(.IN,.OUT)
  E  DO RESP(.OUT,404,"not_found")

OUT ; status + JSON
  S httpStatus=$G(OUT("%HTTP"),200)
  ; Encode OUT -> payload (JSON)
  ; e.g. DO ENCODE^JSON(.OUT,.payload)  or  DO ENCODE^YOURJSON(.OUT,.payload)
  DO ENCODE^JSON(.OUT,.payload) ; <-- placeholder: use your encoder
  QUIT

RESP(OUT,code,msg)
  S OUT("%HTTP")=code S:$G(msg)'="" OUT("error")=msg QUIT
