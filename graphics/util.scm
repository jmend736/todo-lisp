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

(define (d:make-time-subgraph input) ;; Assumes input is alright correct
  (define node-times (sort (map d:times-extract input)
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
        (string-append "{" (string-tail str 2) "};")
        (lp (string-append
              str
              "->t"
              (number->string
                (car times)))
            (cdr times))))
    (let lp ((str "")
             (times times))
      (if (null? times)
        (string-append "{" (string-tail str 2) "};")
        (lp (string-append
              str
              "; "
              (number->string
                (car times)))
            (cdr times))))
    )
  )

decoded-time->string
