(define reader:begin-tasks "--BEGIN--")

(define (reader:read-tasks file-name delimiter)

  (define error? symbol?)
  
  (let lp ((out '())
	   (rest (open-input-file file-name))
	   (valid parser:valid:options?)
	   (number 0))


    
    (let ((line (read-line rest)))
					;base case
      (cond ((eof-object? line) (begin
				  (close-port rest)
				  (reverse out)))
	    
					;blank line - skip
	    ((eq? 0 (string-length (string-trim line)))
	     (lp out rest valid (+ 1 number)))

					;are we reading tasks now?
	    ((equal? `(,reader:begin-tasks)
		  (parser:readline line delimiter))
	     (lp out rest parser:valid:task? (+ 1 number)))

	    (else
	     (let ((new (valid line delimiter)))
	       (if (error? new)
		   `(reader-error ,number ,new ,line)
		   (lp (cons new out) rest  valid (+ 1 number)))))))))





