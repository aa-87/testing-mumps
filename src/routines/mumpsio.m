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
 	s ^MI(":WS","ROUTES","POST","api/problems/list","list^mumpsio")=""
 	s ^MI(":WS","ROUTES","POST","api/problems/get","get^mumpsio")=""
 	s ^MI(":WS","ROUTES","POST","api/problems/facets","facets^mumpsio")=""
 	s ^MI(":WS","ROUTES","OPTIONS","api/problems/list","list^mumpsio")=""
 	s ^MI(":WS","ROUTES","OPTIONS","api/problems/get","get^mumpsio")=""
 	s ^MI(":WS","ROUTES","OPTIONS","api/problems/facets","facets^mumpsio")=""
	s aa("api/problems/list")="list^mumpsio"
 	s aa("api/problems/get")="get^mumpsio"
 	s aa("api/problems/facets")="facets^mumpsio"
 	q
 	;
list(%Q,%R,%A) ;POST /api/problems/list
 	; IN("search")="tree"
	; IN("sort")="title"
	; IN("page")=2
	; IN("limit")=10
	; IN("difficulty","Easy")=1
	; IN("difficulty","Medium")=1
	;OUT("page")=2
	;OUT("limit")=10
	;OUT("total")=37
	;OUT("items",1,"id")=9
	;OUT("items",1,"title")="Binary Tree Inorder Traversal"
	;OUT("items",1,"slug")="bt-inorder"
	;OUT("items",1,"difficulty")="Easy"
	;OUT("items",1,"acceptance")=71.0
	;OUT("items",1,"tags",1)="tree"
	;OUT("items",1,"tags",2)="stack"
	;...
	s %R("header","Access-Control-Allow-Origin")="*"
	s %R("header","Access-Control-Allow-Headers")="Origin, X-Requested-With, Content-Type, Accept, auth, jwt"
	s %R("mime")="application/json"
	i %Q("method")="OPTIONS" q
	I '$D(@%Q("body")) Q
	n in,out
	d decode^aajson(%Q("body"),$na(in))
	d LIST^PROBAPI(.in,.out)
	d encode^aajson($na(out),%R)
	q
	;
get(%Q,%R,%A) ;POST /api/problems/get
 	; IN("slug")="lru-cache"
 	; OUT("id")=3
	; OUT("title")="LRU Cache"
	; OUT("slug")="lru-cache"
	; OUT("difficulty")="Medium"
	; OUT("acceptance")=49.8
	; OUT("description")="Design an LRU cache."
	; OUT("tags",1)="design"
	; OUT("tags",2)="hash-table"
 	S %R("mime")="application/json"
	S %R("header","Access-Control-Allow-Origin")="*"
	S %R("header","Access-Control-Allow-Headers")="Origin, X-Requested-With, Content-Type, Accept, auth, jwt"
	i %Q("method")="OPTIONS" q
	I '$D(@%Q("body")) Q
	n in,out
	d decode^aajson(%Q("body"),$na(in))
	d GET^PROBAPI(.in,.out)
	d encode^aajson($na(out),%R)
	q
	;
facets(%Q,%R,%A) ;
 	; OUT("difficulty","Easy")=4
	; OUT("difficulty","Medium")=4
	; OUT("difficulty","Hard")=2
	; OUT("tags",1,"tag")="graph"
	; OUT("tags",1,"count")=2
	; ...
 	S %R("mime")="application/json"
	S %R("header","Access-Control-Allow-Origin")="*"
	S %R("header","Access-Control-Allow-Headers")="Origin, X-Requested-With, Content-Type, Accept, auth, jwt"
	i %Q("method")="OPTIONS" q
	I '$D(@%Q("body")) Q
	n in,out
	d decode^aajson(%Q("body"),$na(in))
	d FACETS^PROBAPI(.in,.out)
	d encode^aajson($na(out),%R)
	q