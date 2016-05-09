;;;; Predicates

(define predicate?)
(define get-predicate-metadata)
(define set-predicate-metadata!)
(let ((association (make-metadata-association)))
  (set! predicate? (association 'has?))
  (set! get-predicate-metadata (association 'get))
  (set! set-predicate-metadata! (association 'put!)))

(define (guarantee predicate object)
  (if (not (predicate object))
      (error:not-a predicate object)))

(define (error:not-a predicate object)
  (error "Object doesn't satisfy predicate:"
         object
         (if (predicate? predicate)
             (predicate-name predicate)
             predicate)))

(define (is-list-of predicate)
  (lambda (object)
    (and (list? object)
         (every predicate object))))

(define (is-non-empty-list-of predicate)
  (conjoin pair? (is-list-of predicate)))

(define (is-pair-of car-predicate cdr-predicate)
  (lambda (object)
    (and (pair? object)
         (car-predicate (car object))
         (cdr-predicate (cdr object)))))

(define (%memoized-compound-predicate type procedure)
  (let ((memoizer
         (lset-memoizer eqv?
                        hash-by-eqv
                        (lambda (predicates) predicates)
                        (lambda (predicates)
                          (register-compound-predicate!
                           (procedure predicates)
                           type
                           predicates)))))
    (lambda (predicates)
      (let ((predicates (delete-duplicates predicates eqv?)))
        (if (and (pair? predicates) (null? (cdr predicates)))
            (car predicates)
            (memoizer predicates))))))

(define (disjoin . predicates)
  (disjoin* predicates))

(define disjoin*
  (%memoized-compound-predicate 'disjoin
    (lambda (predicates)
      (lambda (object)
        (any (lambda (predicate)
               (predicate object))
             predicates)))))

(define (conjoin . predicates)
  (conjoin* predicates))

(define conjoin*
  (%memoized-compound-predicate 'conjoin
    (lambda (predicates)
      (lambda (object)
        (every (lambda (predicate)
                 (predicate object))
               predicates)))))
