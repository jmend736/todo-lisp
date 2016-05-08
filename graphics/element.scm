;; I imagine being able to pass formats like:
;; (BEGIN END_LIST BOLD COLOR SHAPE)
;; Where the basics are:
;; BEGIN, END_LIST, BEGIN_LIST, END
;; and
;; BOLD, COLOR, SHAPE are built from a generic function

(define (d:generic-element predicate return)
  (lambda (opt)
    (case opt
          ((check) predicate)
          ((return) return)
          (else (error "d:generic-element: invalid operation")))))

(define (d:gen-check gen-element pat)
  ((gen-element 'check) pat))

(define (d:gen-value gen-element pat)
  (if (d:gen-check gen-element pat)
    ((gen-element 'return) pat)
    (error "d:value: Wrong Pattern")))

;; TODO: Expand the predicates
(define d:START
  (d:generic-element symbol? (lambda (x) (list 'start (list x)))))

(define d:START_LIST
  (d:generic-element list? (lambda (x) (list 'start x))))

(define d:END
  (d:generic-element symbol? (lambda (x) (list 'end (list x)))))

(define d:END_LIST
  (d:generic-element list? (lambda (x) (list 'end x))))

(define d:RANK
  (d:generic-element alist? (lambda (x) (list 'props (list 'rank x)))))

(define (option? thing)
  (and (list? thing)
       (= (length thing) 2)))

(define d:OPTION
  (d:generic-element option? (lambda (x) (list 'props x))))

(define d:gen-option
  (lambda (option_name)
    (d:generic-element string? (lambda (x) (list 'props (list option_name x))))))

(define (d:check-format format assl)
  (define (check format element)
    (if (= (length format)
           (length element))
      (let lp ((elem element)
               (form format))
        (if (or (null? elem)
                (null? form))
          #t
          (if (d:gen-check (car form) (car elem))
            (lp (cdr elem) (cdr form))
            (begin
              (pp elem)
              #f))))
      #f))
  (let lp ((lst assl))
    (if (null? lst)
      #t
      (if (check format (car lst))
        (lp (cdr lst))
        #f))))

; ((option 'return) '("rofl" "copter"))
; (d:check-format (list start end option) '((a b ("something" "rofl")) (b c ("something" "rofl"))))
; (d:check-format (list start start) '((a b) (b c)))
; (d:check-format (list start start) '((a b) (b c c)))
; (d:check-format (list start_list start) '(((a b c) b) ((b c d) c d)))
; (d:check-format (list start_list start) '(((a b c) b) ((b c d) c)))

; (d:check-format (list start_list start rank) '(((a b c) b ((a 1) (b 2) (c 3)))
;                                                ((b c d) c ((b 2) (c 3) (d 1)))))

(define (d:convert-element element format)
  (let lp ((el_assl (list '(start) '(end) '(props)))
           (elem element)
           (form format))
    (if (or (null? elem)
            (null? form))
      el_assl
      (let ((f (car form))
            (e (car elem)))
       (lp (update-assl (d:gen-value f e) el_assl) (cdr elem) (cdr form))))))

; (d:convert-element '((a b) b "red") (list d:start_list d:end (d:gen-option "color")))

; (assq 'props (d:convert-element  '((a b c) b ((a 1) (b 2) (c 3)))
;                                 (list start_list end rank)))

(define (d:convert format assl)
  (map (lambda (e) (d:convert-element e format)) assl))

; (d:convert (list start end) '((a b) (b c)))

(define (d:elem-start elem)
  (assq 'start elem))

(define (d:elem-end elem)
  (assq 'end elem))

(define (d:elem-props elem)
  (assq 'props elem))

(d:elem-props '((start a) (end b) (props)))

(define (d:elem-list-empty? elem-list)
  (= 1 (length elem-list)))

; (d:elem-list-empty? '(end))
; (d:elem-list-empty? '(end 1))

; (define (d:ops elem))

(define (d:namestr start end)
  (string-append "edge:" (symbol->string start) "->" (symbol->string end)))

; (d:namestr 'a 'b)

(define (d:elem->graph elem #!optional graph_initial)
  (if (eq? graph_initial #!default) ; If no graph is passed,
    (d:elem->graph elem '((graph))) ; call with an empty graph
    (let lp ((graph graph_initial)
             (start (cadr (d:elem-start elem)))
             (end (cadr (d:elem-end elem)))
             (props (if (> (length (d:elem-props elem)) 1)
                      (cdr (d:elem-props elem))
                      (list))))
      (cond ((null? start) graph)
            ((null? end) (lp graph (cdr start) (cadr (d:elem-end elem)) props))
            (else (lp (if (assq (d:namestr (car start) (car end)) graph) ; Add nodes
                        (error "wut") ; Not already in the graph
                        (append graph (list (list (d:namestr (car start) (car end))
                                                  (car start) (car end) props)))) ; Already in the graph
                      start (cdr end) props))))))

; (d:elem->graph '((start (a c d)) (end (b)) (props ("color" "red") ("style" "dotted"))))

; (d:elem->graph '((start (a c d)) (end (b)) (props)))

(define (d:node? str)
  (string=? (substring str 0 5) "node:"))

(define (d:edge? str)
  (string=? (substring str 0 5) "edge:"))

; (d:node? "node:dwjiaod")
; (d:node? "djoiwa")

(define d:analyze (simple-generic-procedure 'd:analyze 1))

(define-generic-procedure-handler d:analyze
                                  (all-args 1 d:node?)
                                  (lambda (node)
                                    (pp "node")))

(define-generic-procedure-handler d:analyze
                                  (all-args 1 d:edge?)
                                  (lambda (edge)
                                    (lambda (element)
                                      (let ((start (car element))
                                            (end (cadr element)))
                                        (if (not (null? (caddr element)))
                                          (let lp ((str (string-append
                                                          (symbol->string
                                                            start)
                                                          "->"
                                                          (symbol->string
                                                            end)
                                                          " ["))
                                                   (props (caddr element)))
                                            (if (null? props)
                                              (string-append str "]; ")
                                              (lp (string-append
                                                    str
                                                    (caar props)
                                                    "="
                                                    (cadar props))
                                                  (cdr props))))
                                          (string-append
                                            (symbol->string start)
                                            "->"
                                            (symbol->string end)
                                            "; "
                                            ))))))


(define (d:graph->str graph_initial)
  (let lp ((str "digraph G {")
           (graph (list-tail graph_initial 1)))
    (cond ((null? graph) (string-append str "}"))
          ((eq? (car graph) '(graph)) (lp str (cdr graph)))
          (else
            (lp (string-append str ((d:analyze (caar graph)) (cdar graph)))
                (cdr graph))))))


(d:graph->str (d:elem->graph '((start (a c d)) (end (b)) (props ("color" "red")))))

; (define (d:elem->str elem)
;   (let lpstart ((str "")
;                 (start (cadr (d:elem-start elem)))
;                 (end (cadr (d:elem-end elem))))
;     (cond ((null? start) str)
;           ((null? end) (lpstart str (cdr start) (cadr (d:elem-end elem))))
;           (else (lpstart (string-append
;                            str (symbol->string
;                              (car start))
;                            "->"
;                            (symbol->string
;                              (car end))
;                            ";")
;                          start (cdr end))))))

;(d:elem->str '((start (a b)) (end (b)) (props)))
;(d:elem->str '((start (a b)) (end (b c d e)) (props)))
