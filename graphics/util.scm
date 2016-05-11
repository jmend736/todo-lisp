;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;                               todo-lisp
;;
;; Filename: util.scm
;;
;; Description:
;;          Utility functions for graphics block
;;
;; Functions:
;;          (d:make-time-subgraph [input list]) ~ Create time subgraph string
;;          (d:times-extract [input list]) ~ Extract times/real times
;;          (d:times-extract-names [input list]) ~ Extract times/name strings
;;          (q [string]) ~ Surround with quotes
;;          (update-assl [new] [assl]) ~ Updates assl to add new
;;
;;
;; Author: jmend
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (update-assl new assl)
  ;; Add add elements into a certain element in an association list
  (if new
    (let ((old (assq (car new) assl)))
     (append (del-assq (car new) assl) (list (append old (list (cadr new))))))
    assl))

; (update-assl '(a b) '((a c) (b d)))

(define (q str) ; Surround string with quotes
  (string-append "\"" str "\""))


(define d:times-extract
  (lambda (x)
    `(,(cadr (assoc 'block-id x)) ,(decoded-time->universal-time (cadadr (assoc 'start-time x))))))

(define d:times-extract-names
  (lambda (x)
    `(,(decoded-time->string (cadadr (assoc 'start-time x))) ,(decoded-time->universal-time (cadadr (assoc 'start-time x))))))

(define (d:make-time-subgraph input) ;; Assumes input is alright correct
  (define node-times (sort (map d:times-extract input)
                           (lambda (x y)
                             (let ((xt (cadr x))
                                   (yt (cadr y)))
                               (< xt yt)))))
  (define node-names (sort (map d:times-extract-names input)
                           (lambda (x y)
                             (let ((xt (cadr x))
                                   (yt (cadr y)))
                               (< xt yt)))))
  (define times (sort (map (lambda (x)
                             (decoded-time->universal-time
                               (cadadr (assoc
                                         'start-time
                                         x))))
                           input)
                      <))
  (string-append
    (let lp ((str "")
             (times node-times))
      (if (null? times)
        str
        (lp (string-append
              str
              "{rank=same;\""
              (symbol->string
                (caar times))
              "\" t"
              (number->string
                (cadar times))
              "};")
            (cdr times))))
    (let lp ((str "")
             (times times))
      (if (null? times)
        (string-append "{"
                       (string-tail str 2)
                       (let lpin ((str "")
                                (times node-names))
                         (if (null? times)
                           str
                           (lpin (string-append
                                 str
                                 "; "
                                 "t"
                                 (number->string
                                   (cadar times))
                                 "[label="
                                 "\""
                                (caar times)
                                 "\""
                                    "]")
                               (cdr times))))
                       "};")
        (lp (string-append
              str
              "->t"
              (number->string
                (car times)))
            (cdr times))))
    )
  )

decoded-time->string
