;;; Task Visualizer for todo-lisp
;;
;; Input: Tasks
;; Output:
;;   - Writing .dot file
;;   - Output .js to output to browsers
;;   - Figure out how to make a pseudo-table schedule via graphviz

(load "util")
(load "io")
(load "element")


(define (d:factory format)
  (lambda (assl filename)
    (if (d:check-format format assl)
      (let ((converted (d:convert format assl)))
        (pp "----------------------")
        (pp converted)
        (let lp ((str "digraph G {")
                 (l converted))
          (cond ((> (length l) 0)
                 (lp (string-append str (d:elem->str (car l))) (cdr l)))
                ((= (length l) 0) (string-append str "}"))
                (else 0))))
      (error "d:factory: assl format error"))))

((d:factory (list start_list end)) '(((a b) e) ((a) c)) "Something")

;((d:factory (list start_list end_list)) '(((a b) (wa dwg dwa jia)) ((a) (djw dwa))) "Something")

