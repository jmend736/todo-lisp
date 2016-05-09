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
(load "format")
(load "element")


(define (d:factory format)
  (lambda (assl filename)
    (if (d:check-format format assl)
      (let ((converted (d:convert format assl)))
        (let lp ((str "digraph G {")
                 (l converted))
          (cond ((> (length l) 0)
                 (lp (string-append str (d:elem->str (car l))) (cdr l)))
                ((= (length l) 0) (string-append str "}"))
                (else 0))))
      (error "d:factory: assl format error"))))


(define default-options "node [shape=record,width=.1,height=.1]; nodeset=.5; ranksep=.5; rankdir=LR;")

(define (d:factory format #!optional options)
  (if (eq? options #!default)
    (d:factory format default-options)
    (lambda (assl filename)
      (if (d:check-format format assl)
        (let lp ((graph (d:init-graph))
                 (converted (d:convert format assl)))
          (if (null? converted)
            (d:graph->str graph options assl)
            (lp (d:elem->graph (car converted) graph) (cdr converted))))
        (error "d:factory: assl format error")))))


; ((d:factory (list d:start_list d:end)) '(((a b) e) ((a) c)) "Something")

; ((d:factory (list start_list end_list)) '(((a b) (wa dwg dwa jia)) ((a) (djw dwa))) "Something")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                   Format we're using
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


;; Generic Elements
;   - start : '(start <symbol>)
;   - end : '(end <symbol>)
;   - props : '(props (option_name value))
;   - nprops : '(nprops (option_name <node> value))
;   - special : '(special <anything>)




; ((d:factory format) '((a (b c d) "label" "taskid" "duration" "rank" "deadline")) "sth")
; 
; 
; (write-dot-file ((d:factory (list d:start d:end_list (d:gen-option "color")))
;    '((a (b c d) "red") (d (e r) "blue")) "sth") "sth")
; 
; (write-dot-file ((d:factory (list d:start d:end_list (d:gen-node-option "label")))
;   '((a (b c d) (a "red")) (d (e r) (d "blue"))) "sth") "sth")
; 
; ((d:factory (list d:start d:end_list (d:gen-node-option "label") (d:special "rank")))
;   '((a (b c d) (a "red") ((a d))) (d (e r) (d "blue") ((e c)))) "sth")
; 
; (write-dot-file ((d:factory (list d:start d:end_list (d:gen-node-option "label") (d:special "rank")))
;   '((a (b c d) (a "red") ((a d))) (d (e r) (d "blue") ((e c)))) "sth") "sth")


; (write-dot-file ((d:factory final-format) '((abc (r f o) "What is this block lol" a a a a)) "sth") "sth")




(define d:blockid
  (d:generic-element (lambda (x) (and (pair? x) (eq? (car x) 'block-id)))
                     (lambda (x) (list 'end (list (cadr x))))))


(define d:dependentids
  (d:generic-element (lambda (x) (and (pair? x) (eq? (car x) 'dependent-ids)))
                     (lambda (x) (list 'start (if (> (length (cadr x)) 0)
                                                (cadr x)
                                                (list d:nothing))))))

(define d:starttime
  (d:generic-element (lambda (x) (and (pair? x) (eq? (car x) 'start-time)))
                     (lambda (x) (list 'special (list (cadadr x))))))


(d:gen-check d:dependentids '(dependent-ids ()))

(define d:description
  (d:generic-element (lambda (x) (and (pair? x) (eq? (car x) 'description)))
                     (lambda (desc)
                       (list 'nprops (list "label" 'end (string-append "\"" (cadr desc) "\""))))))

(define d:unused
  (d:generic-element (lambda (x) #t) (lambda (x) #f)))

(define final-format (list d:blockid d:dependentids d:description d:unused d:unused d:unused d:unused))

(define test-input (list `((block-id a1-1)
         (dependent-ids (a2-1))
         (description "Test text")
         (task-id "1")
         (duration (duration 0 3 0))
         (start-time (instant ,(make-decoded-time 0 0 12 9 5 2016)))
         (deadline (instant ,(make-decoded-time 0 0 17 9 5 2016))))
       `((block-id a2-1)
          (dependent-ids ())
          (description "Test text 2")
          (task-id "2")
          (duration (duration 0 0 30))
          (start-time (instant ,(make-decoded-time 0 0 9 9 5 2016)))
          (deadline (instant ,(make-decoded-time 0 0 17 9 5 2016))))))

(write-dot-file ((d:factory final-format) test-input "sth") "sth")



(let lp ((graph '())
         (times (sort (map d:times-extract test-input) (lambda (x y)
                                                         (let ((xt (cadr x))
                                                               (yt (cadr y)))
                                                           (< xt yt))))))
  (pp times)
    (if (null? times)
      graph
      (lp (append graph '((start) (end) (props) (nprops) (special))) (cdr times)))
 )



(define input1 (sort (map d:times-extract test-input)
       (lambda (x y) (let ((xt (cadr x)) (yt (cadr y))) (< xt yt)))))
(define input2 (sort (map (lambda (x)
              (decoded-time->universal-time (cadadr (assoc 'start-time x)))) test-input) <))

(let lp ((str "")
         (times input1))
  (if (null? times)
    str
    (lp (string-append
          str
          "{rank=same;"
          (symbol->string
            (caar times))
          " t"
          (number->string
            (cadar times))
          "};")
        (cdr times))))

(let lp ((str "")
         (times input2))
  (if (null? times)
    (string-append "{" (string-tail str 2) "};")
    (lp (string-append
          str
          "->n"
          (number->string
            (car times)))
        (cdr times))))
