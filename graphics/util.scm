(define (update-assl new assl)
  ;; Add add elements into a certain element in an association list
  (let ((old (assq (car new) assl)))
    (append (del-assq (car new) assl) (list (append old (list (cadr new)))))))

; (update-assl '(a b) '((a c) (b d)))
