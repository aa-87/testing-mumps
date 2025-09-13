PROBLOAD ; Seed sample problems and simple indexes
  NEW id,k,tags,desc,diff
  KILL ^PROB,^PROBIDX
  ; id=1..N
  DO ADD(1,"Two Sum","two-sum","Easy","arrays^hash-table","Find two numbers that add to target.",47.3)
  DO ADD(2,"Reverse Linked List","reverse-linked-list","Easy","linked-list","Reverse a singly linked list.",64.2)
  DO ADD(3,"LRU Cache","lru-cache","Medium","design^hash-table","Design an LRU cache.",49.8)
  DO ADD(4,"Course Schedule","course-schedule","Medium","graph^topological-sort","Detect if you can finish all courses.",45.1)
  DO ADD(5,"Median of Two Sorted Arrays","median-two-arrays","Hard","array^divide-and-conquer","Find median in log-time.",39.4)
  DO ADD(6,"Valid Parentheses","valid-parentheses","Easy","stack","Check if parentheses are valid.",76.2)
  DO ADD(7,"Number of Islands","number-of-islands","Medium","graph^dfs^bfs","Count islands in a grid.",55.9)
  DO ADD(8,"Regular Expression Matching","regex-matching","Hard","dp^string","Implement regex matching with '.' and '*'.",28.7)
  DO ADD(9,"Binary Tree Inorder Traversal","bt-inorder","Easy","tree^stack","Return inorder traversal of a binary tree.",71.0)
  DO ADD(10,"Longest Substring Without Repeating","longest-substring","Medium","string^sliding-window","Find longest substring without repeating characters.",51.6)
  QUIT

ADD(id,title,slug,diff,tags,desc,acc)
  NEW i,tag,tl SET tl=$$LOW^PROBAPI(title)
  SET ^PROB(id,"id")=id
  SET ^PROB(id,"title")=title
  SET ^PROB(id,"slug")=slug
  SET ^PROB(id,"difficulty")=diff
  SET ^PROB(id,"tags")=tags
  SET ^PROB(id,"desc")=desc
  SET ^PROB(id,"accept")=acc
  SET ^PROBIDX("title",tl,id)=""     ; case-insensitive title index
  SET ^PROBIDX("diff",diff,id)=""    ; difficulty index
  FOR i=1:1:$L(tags,"^") SET tag=$P(tags,"^",i) QUIT:tag=""  SET ^PROBIDX("tag",tag,id)=""
  QUIT
