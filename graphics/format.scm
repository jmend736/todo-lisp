;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;                               todo-lisp
;;
;; Filename: format.scm
;;
;; Description:
;;          Format helper functions for project
;;
;; Functions:
;;          (invisble-node-format n) ~ Applies node properties to make it invis
;;          default-options ~ Default graph options
;;
;;
;; Author: jmend
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (invisible-node-format n)
    (list (list "style" n "invis") (list "height" n ".01") (list "width" n ".01")
          (list "fontsize" n "1")))


(define default-options "node [shape=record,width=.1,height=.1]; nodeset=.5; ranksep=.5; rankdir=LR;")

