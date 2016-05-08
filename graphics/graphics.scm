;;; Task Visualizer for todo-lisp
;;
;; Input: Tasks
;; Output:
;;   - Writing .dot file
;;   - Output .js to output to browsers
;;   - Figure out how to make a pseudo-table schedule via graphviz

;; From pset 3
(load (list "ps3/utils"                     ;from common
            "ps3/collections"               ;from common
            "ps3/memoizers"                 ;from common
            "ps3/predicates"                ;from common
            "ps3/predicate-metadata"        ;from common
            "ps3/predicate-counter"         ;from common
            "ps3/applicability"             ;from common
            "ps3/generic-procedures"        ;from common
            ))

(load "util")
(load "io")
(load "element")


(define (d:factory format)
  (lambda (assl filename)
    (if (d:check-format format assl)
      (let ((converted (d:convert format assl)))
        (pp "----------------------")
        (pp converted)
        (let lp ((str "digraph G {")
                 (l converted))
          (cond ((> (length l) 0)
                 (lp (string-append str (d:elem->str (car l))) (cdr l)))
                ((= (length l) 0) (string-append str "}"))
                (else 0))))
      (error "d:factory: assl format error"))))

(define (d:factory format)
  (lambda (assl filename)
    (if (d:check-format format assl)
      (let lp ((graph (d:init-graph))
               (converted (d:convert format assl)))
        (if (null? converted)
          (d:graph->str graph)
          (lp (d:elem->graph (car converted) graph) (cdr converted))))
      (error "d:factory: assl format error"))))


; ((d:factory (list d:start_list d:end)) '(((a b) e) ((a) c)) "Something")

; ((d:factory (list start_list end_list)) '(((a b) (wa dwg dwa jia)) ((a) (djw dwa))) "Something")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;('workblock
;    ('block_id <id>)
;    ('dependent_ids <dependencies>)
;    ('description <description>)
;    ('taskid <taskid>)
;    ('duration <duration>)
;    ('starttime <deadline>)
;    ('deadline <deadline>))

; (define FORMAT (list d:start d:end_list (d:gen-option "node:label") (d:gen-option "c:taskid")
;           (d:gen-option "c:duration") (d:gen-option "node:rank")
;           (d:gen-option "c:deadline")))
; 
; 
; ((d:factory format) '((a (b c d) "label" "taskid" "duration" "rank" "deadline")) "sth")


; (write-dot-file ((d:factory (list d:start d:end_list (d:gen-option "color")))
;   '((a (b c d) "red") (d (e r) "blue")) "sth") "sth")

(write-dot-file ((d:factory (list d:start d:end_list (d:gen-node-option "color")))
  '((a (b c d) (a "red")) (d (e r) (d "blue"))) "sth") "sth")

((d:factory (list d:start d:end_list (d:gen-node-option "color")))
  '((a (b c d) (a "red")) (d (e r) (d "blue"))) "sth")

