;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;                               todo-lisp
;;
;; Filename: generate.scm
;;
;; Description:
;;          Use elements to generate a graph
;;
;; Functions:
;;          (d:analyze [elem]) ~ Gen Proc. to analyze special elements
;;          (d:elem->graph [elem list] [input list]) ~ Takes elem list and returns a graph
;;          (d:graph->str [graph] [options] [input list]) ~ graph -> string output
;;          (d:graph->str:element [elem]) ~ Takes element and return string
;;
;;
;; Author: jmend
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Functions to extract different types from elements
(define (d:elem-start elem) (assq 'start elem))
(define (d:elem-end elem) (assq 'end elem))
(define (d:elem-props elem) (assq 'props elem))
(define (d:elem-nprops elem) (assq 'nprops elem))
(define (d:elem-special elem) (assq 'special elem))
(define d:nothing '*nothing*)

;; Empty list check
(define (d:elem-list-empty? elem-list)
  (= 1 (length elem-list)))

;; Generate name
;; Could be useful for more complicated applications
(define (d:namestr start end)
  (string-append "edge:" (symbol->string start) "->" (symbol->string end)))

;; Initialize empty graph
(define (d:init-graph)
  '((graph)))

;; Take an element of a graph and add it to a graph
(define (d:elem->graph elem graph_initial)
  (let lp ((graph graph_initial)
           (start (cadr (d:elem-start elem)))
           (end (cadr (d:elem-end elem)))
           (props (if (> (length (d:elem-props elem)) 1)
                    (cdr (d:elem-props elem))
                    (list)))
           (nprops (if (> (length (d:elem-nprops elem)) 1)
                     (cdr (d:elem-nprops elem))
                     (list)))
           (special (if (> (length (d:elem-special elem)) 1)
                      (cdr (d:elem-special elem))
                      (list))))
    (cond ((and (= (length start) 1) (eq? d:nothing (car start)))
           (append graph (list (list (d:namestr (car start) (car end))
                                     (symbol-append '*nothing* (car end))
                                     (car end)
                                     (append props (list (list "style" "invis")))
                                     (append nprops (invisible-node-format (symbol-append '*nothing* (car end))))
                                     special))))
          ((null? start) graph)
          ((null? end) (lp graph (cdr start) (cadr (d:elem-end elem)) props nprops special))
          (else (lp (if (assq (d:namestr (car start) (car end)) graph) ; Add nodes
                      (error "Already in the graph") ; already in the graph
                      (append graph (list (list (d:namestr (car start) (car end))
                                                (car start) (car end) props nprops special)))) ; Already in the graph
                    start (cdr end) props nprops special)))))

;; Utility function to process nprops
(define (d:process-nprops nprops str)
  (if (null? nprops)
    str
    (let ((nprop (car nprops)))
      (string-append str
                    " "
                    (symbol->string (cadr nprop))
                    " ["
                    (car nprop)
                    "="
                    (caddr nprop)
                    "];"
                    ))))

;; Generic procedure used to analyze special elements
(define d:analyze (simple-generic-procedure 'd:analyze 1))

(define (rank-pred? thing)
  (assoc "rank" thing ))

(define-generic-procedure-handler d:analyze
    (all-args 1 rank-pred?)
    (lambda (props)
      (let ((rank (caadr (assoc "rank" props)))
            (start ))
        (string-append "{rank=same;" (symbol->string (car rank)) " "
                                     (symbol->string (cadr rank)) "};"))))

;; If no method to process, ignore elment
(define-generic-procedure-default-handler d:analyze
        (lambda (props)
          ""))

;; Convert a graph element into a string
(define (d:graph->str:element element)
  (lambda (element)
    (let ((start (car element))
          (end (cadr element))
          (props0 (caddr element))
          (nprops0 (cadddr element))
          (special (fifth element)))
      (string-append
        (q (symbol->string start))
        "->"
        (q (symbol->string end))
        (if (null? props0)
          ""
          (let lp ((str " [")
                   (props props0))
            (if (null? props)
              (string-append str "]")
              (lp (string-append str (caar props) "=" (cadar props) ",")
                  (cdr props)))
            ))
        (if (null? nprops0)
          ";"
          (let lp ((str "")
                   (nprops nprops0))
            (if (null? nprops)
              (string-append str ";")
              (lp (string-append str
                                 "; "
                                 (cond
                                   ((eq? (cadar nprops) 'start)
                                    (q (symbol->string start)))
                                   ((eq? (cadar nprops) 'end)
                                    (q (symbol->string end)))
                                   (else
                                    (q (symbol->string (cadar nprops)))))
                                 " ["
                                 (caar nprops)
                                 "="
                                 (caddar nprops)
                                 "]")
                  (cdr nprops)))
            ))
        (if (null? special)
          ""
          (d:analyze special))))))


;; Graph to string function
;; Also creates time subgraph for our project
(define (d:graph->str graph_initial options original)
  (let lp ((str (string-append "digraph G {" options))
           (graph (list-tail graph_initial 1)))
    (cond ((null? graph) (string-append str (d:make-time-subgraph original) "}"))
          ((eq? (car graph) '(graph)) (lp str (cdr graph)))
          (else
            (lp (string-append str ((d:graph->str:element (caar graph)) (cdar graph)))
                (cdr graph))))))

