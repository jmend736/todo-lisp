(load-option 'synchronous-subprocess)

;(let ((port (open-output-string))
      ;(file-port (open-output-file "hello.html")))
  ;(and (= (run-shell-command "dot -Tps pls.dot -o graph1.ps" 'output port)
          ;0)
       ;(write-string "Hello World" file-port)
       ;(flush-output file-port)
       ;(get-output-string port)
       ;(and (= (run-shell-command "gnome-open hello.html &" 'output port)
               ;0)
            ;(get-output-string port))))

; (pp '((a (b)) (b (c d))))

(define (assl->dot:elem element)
  (let lp ((s (symbol->string (car element)))
           (t (cadr element))
           (output ""))
    (if (> (length t) 0)
      (lp s (cdr t) (string-append output s "->" (symbol->string (car t)) ";"))
      output)))

; (assl->dot:elem '(a (a b c)))


(define (assl->dot input)
  (let lp ((i 0)
           (str "digraph G {")
           (l input))
    (cond ((> (length l) 0)
           (lp (+ i 1) (string-append str (assl->dot:elem (car l))) (cdr l)))
          ((= (length l) 0) (string-append str "}"))
      (else 0))))

; (assl->dot '((a (b)) (b (c d))))

;; TODO: Make this more generic
(define (assl->graph assl filename)
  (let ((file-port (open-output-file (string-append filename ".dot"))))
    (write-string (assl->dot assl) file-port)
    (flush-output file-port)
    (let ((port (open-output-string)))
      (and (= (run-shell-command (string-append "dot -Tps "
                                                filename
                                                " -o "
                                                (string-append filename ".ps")) 'output port))
           0)
      (get-output-string port))))

;(assl->graph '((a (b d)) (b (c d))) "plss.dot")



