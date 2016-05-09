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

(define (option? thing)
  (and (list? thing)
       (= (length thing) 2)))

(define d:OPTION
  (d:generic-element option? (lambda (x) (list 'props x))))

(define d:gen-option
  (lambda (option_name)
    (d:generic-element string? (lambda (x) (list 'props (list option_name x))))))

;; 'TODO' Make more stringent

(define d:gen-node-option
  (lambda (option_name)
    (d:generic-element list? (lambda (x) (list 'nprops (list option_name (first x)
                                                             (second x)))))))

(define d:special
  (lambda (option_name)
    (d:generic-element list? (lambda (x) (list 'special (list option_name x))))))

; (d:gen-value (d:gen-node-option "label") '(a "newname"))
; -> (nprops ("label" a "newname"))

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
  (let lp ((el_assl (list '(start) '(end) '(props) '(nprops) '(special)))
           (elem element)
           (form format))
    (if (or (null? elem)
            (null? form))
      el_assl
      (let ((f (car form))
            (e (car elem)))
       (lp (update-assl (d:gen-value f e) el_assl) (cdr elem) (cdr form))))))

; (d:convert-element '((a b) b "red" (a "rofl") (a "10")) (list d:start_list d:end (d:gen-option "color")
;                                           (d:gen-node-option "label") (d:special "rank")))

; (assq 'props (d:convert-element  '((a b c) b ((a 1) (b 2) (c 3)))
;                                 (list start_list end rank)))

(define (d:convert format assl)
  (map (lambda (e) (d:convert-element e format)) assl))

; (d:convert (list start end) '((a b) (b c)))

(define (d:elem-start elem) (assq 'start elem))

(define (d:elem-end elem) (assq 'end elem))

(define (d:elem-props elem) (assq 'props elem))

(define (d:elem-nprops elem) (assq 'nprops elem))

(define (d:elem-special elem) (assq 'special elem))

(define d:nothing '*nothing*)

 ;(d:elem-props '((start a) (end b) (props)))

(define (d:elem-list-empty? elem-list)
  (= 1 (length elem-list)))

; (d:elem-list-empty? '(end))
; (d:elem-list-empty? '(end 1))

; (define (d:ops elem))

(define (d:namestr start end)
  (string-append "edge:" (symbol->string start) "->" (symbol->string end)))

; (d:namestr 'a 'b)

(define (d:init-graph)
  '((graph)))

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

; (d:elem->graph '((start (a c d)) (end (b)) (props)))

; TODO Remove these?
; (define (d:node? str)
;   (string=? (substring str 0 5) "node:"))
;
; (define (d:edge? str)
;   (string=? (substring str 0 5) "edge:"))


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

(define d:analyze (simple-generic-procedure 'd:analyze 1))

(define (rank-pred? thing)
  (assoc "rank" thing ))

; (rank-pred? '(("roflrofl" 'aaaa) ("rnk" 'djwoia)))
; (rank-pred? '(("roflrofl" 'aaaa) ("rank" 'djwoia)))

(define-generic-procedure-handler d:analyze
    (all-args 1 rank-pred?)
    (lambda (props)
      (let ((rank (caadr (assoc "rank" props)))
            (start ))
        (string-append "{rank=same;" (symbol->string (car rank)) " "
                                     (symbol->string (cadr rank)) "};"))))

; (d:analyze '(("rank" (a b))))

(define-generic-procedure-default-handler d:analyze
        (lambda (props)
          ""))


; (d:graph->str:element '(a b () (("task" start "end")) ()))

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


(define (d:graph->str graph_initial options original)
  (let lp ((str (string-append "digraph G {" options))
           (graph (list-tail graph_initial 1)))
    (cond ((null? graph) (string-append str (d:make-time-subgraph original) "}"))
          ((eq? (car graph) '(graph)) (lp str (cdr graph)))
          (else
            (lp (string-append str ((d:graph->str:element (caar graph)) (cdar graph)))
                (cdr graph))))))

