;;;; Generic procedures

(define generic-procedure?)
(define get-generic-procedure-metadata)
(define set-generic-procedure-metadata!)
(let ((association (make-metadata-association)))
  (set! generic-procedure? (association 'has?))
  (set! get-generic-procedure-metadata (association 'get))
  (set! set-generic-procedure-metadata! (association 'put!)))

(define (make-generic-procedure name arity dispatcher)
  (let* ((metadata
          (make-generic-metadata name
                                 arity
                                 (dispatcher)
                                 (get-default-handler name)))
         (procedure
          (lambda args
            (generic-procedure-dispatch metadata args))))
    (set-generic-procedure-metadata! procedure metadata)
    procedure))

(define (simple-generic-procedure name arity)
  (make-generic-procedure name arity simple-generic-dispatcher))

(define (get-default-handler name)
  (lambda args
    (error "Inapplicable generic procedure:" name args)))

(define (generic-procedure-dispatch metadata args)
  (apply (get-generic-procedure-handler metadata args) args))

(define (get-generic-procedure-handler metadata args)
  (or ((generic-metadata-getter metadata) args)
      (generic-metadata-default-handler metadata)))

(define (define-generic-procedure-handler proc applicability
                                          handler)
  ((generic-metadata-adder
    (get-generic-procedure-metadata proc))
   applicability
   handler))

(define (define-generic-procedure-default-handler proc handler)
  (set-generic-metadata-default-handler!
   (get-generic-procedure-metadata proc)
   handler))

(define (generic-procedure-name proc)
  (generic-metadata-name (get-generic-procedure-metadata proc)))

(define (generic-procedure-arity proc)
  (generic-metadata-arity (get-generic-procedure-metadata proc)))

;;;; Metadata

(define-record-type <generic-metadata>
    (%make-generic-metadata name arity default-handler getter
                            adder)
    generic-metadata?
  (name generic-metadata-name)
  (arity generic-metadata-arity)
  (default-handler generic-metadata-default-handler
                   set-generic-metadata-default-handler!)
  (getter generic-metadata-getter)
  (adder generic-metadata-adder))

(define (make-generic-metadata name arity dispatcher
                               default-handler)
  (%make-generic-metadata name
                          arity
                          default-handler
                          (dispatcher 'get-handler)
                          (dispatcher 'add-handler!)))

;;;; Dispatcher implementations

(define (simple-generic-dispatcher)
  (let ((rules '()))

    (define (get-handler args)
      (let ((rule
             (find (lambda (rule)
                     (is-applicable? (car rule) args))
                   rules)))
        (and rule
             (cdr rule))))

    (define (add-handler! applicability handler)
      (set! rules
            (cons (cons applicability handler)
                  rules)))

    (lambda (operator)
      (case operator
        ((get-handler) get-handler)
        ((add-handler!) add-handler!)
        (else (error "Unknown operator:" operator))))))

(define (trie-generic-dispatcher)
  (let ((base-dispatcher (simple-generic-dispatcher))
        (trie (make-trie)))

    (define (get-handler args)
      (get-a-value trie args))

    (define (add-handler! applicability handler)
      ((base-dispatcher 'add-handler!) applicability handler)
      (for-each (lambda (path)
                  (set-path-value! trie path handler))
                applicability))

    (lambda (operator)
      (case operator
        ((get-handler) get-handler)
        ((add-handler!) add-handler!)
        (else (base-dispatcher operator))))))

(define (cached-generic-dispatcher get-key)
  (let ((base-dispatcher (simple-generic-dispatcher)))
    (let ((get-handler
           (simple-memoizer eqv?
                            hash-by-eqv
                            (lambda (args) (map get-key args))
                            (base-dispatcher 'get-handler))))
      (lambda (operator)
        (case operator
          ((get-handler) get-handler)
          (else (base-dispatcher operator)))))))
