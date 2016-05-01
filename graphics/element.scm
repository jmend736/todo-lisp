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
(define START
  (d:generic-element symbol? (lambda (x) (list 'start (list x)))))

(define START_LIST
  (d:generic-element list? (lambda (x) (list 'start x))))

(define END
  (d:generic-element symbol? (lambda (x) (list 'end (list x)))))

(define END_LIST
  (d:generic-element list? (lambda (x) (list 'end x))))

(define RANK
  (d:generic-element alist? (lambda (x) (list 'props (list 'rank x)))))

;; TODO: Make properties

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
            #f)))
      #f))
  (let lp ((lst assl))
    (if (null? lst)
      #t
      (if (check format (car lst))
        (lp (cdr lst))
        #f))))

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

 ;(d:convert-element '((a b) b) (list start_list end))

; (assq 'props (d:convert-element  '((a b c) b ((a 1) (b 2) (c 3)))
;                                 (list start_list end rank)))

(define (d:convert format assl)
  (map (lambda (e) (d:convert-element e format)) assl))


; (d:convert (list start end) '((a b) (b c)))

(define (d:elem-start elem)
  (assq 'start elem))

(define (d:elem-end elem)
  (assq 'end elem))

(define (d:elem-list-empty? elem-list)
  (= 1 (length elem-list)))

; (d:elem-list-empty? '(end))
; (d:elem-list-empty? '(end 1))

(define (d:elem->str elem)
  (let lpstart ((str "")
                (start (cadr (d:elem-start elem)))
                (end (cadr (d:elem-end elem))))
    (cond ((null? start) str)
          ((null? end) (lpstart str (cdr start) (cadr (d:elem-end elem))))
          (else (lpstart (string-append
                           str (symbol->string
                             (car start))
                           "->"
                           (symbol->string
                             (car end))
                           ";")
                         start (cdr end))))))

;(d:elem->str '((start (a b)) (end (b)) (props)))
;(d:elem->str '((start (a b)) (end (b c d e)) (props)))
