;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;                               todo-lisp
;;
;; Filename: element.scm
;;
;; Description:
;;          Take input list and generate element list
;;
;; Functions:
;;          (d:check-format [format] [input list]) ~ Pred to make sure input list is correct
;;          (d:convert [format] [input list]) ~ Convert input list input elements
;;          (d:convert-element [format] [element]) ~ Convert single list entry into element
;;
;;
;; Author: jmend
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (d:generic-element predicate return)
  (lambda (opt)
    (case opt
          ((check) predicate)
          ((return) return)
          (else (error "d:generic-element: invalid operation")))))

;; Utility functions
(define (d:gen-check gen-element pat)
  ((gen-element 'check) pat))

(define (d:gen-value gen-element pat)
  (if (d:gen-check gen-element pat)
    ((gen-element 'return) pat)
    (error "d:value: Wrong Pattern")))


;; Example gen-elements
;;
;; To write your own the only requirement is that they return either
;; (start (<start nodes>)) : list of symbols
;; (end (<end nodes>)) : list of symbols
;; (props (<property> <value>)) : pair of strings
;; (nprops (<property> <node> <value>)) : pair of strings but <node> is a symb
;; (special <special>) : Can return anything
;;      - You must edit the d:analyze generic-procedure to process it correctly

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

(define d:gen-node-option
  (lambda (option_name)
    (d:generic-element list? (lambda (x) (list 'nprops (list option_name (first x)
                                                             (second x)))))))

(define d:special
  (lambda (option_name)
    (d:generic-element list? (lambda (x) (list 'special (list option_name x))))))


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

;; Convert from input to an element

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

;; Convert input list to a list of element

(define (d:convert format assl)
  (map (lambda (e) (d:convert-element e format)) assl))


