
;;this is the divider in the text file - used
;;to separate schedule options from tasks 
(define reader:task-separator "--BEGIN--")


;;reads a text file
(define (reader:read-tasks file-name field-delimiter task-separator)

  (define error? symbol?)
  
  (let lp ((out '())
	   (rest (open-input-file file-name))
	   (valid? parser:valid:options?)
	   (number 1))


    
    (let ((line (read-line rest)))
					;base case
      (cond ((eof-object? line) (begin
				  (close-port rest)
				  (reverse out)))
	    
					;blank line - skip
	    ((eq? 0 (string-length (string-trim line)))
	     (lp out rest valid? (+ 1 number)))

					;are we reading tasks now?
	    ((equal? `(,task-separator)
		  (parser:readline line field-delimiter))
	     (lp out rest parser:valid:task? (+ 1 number)))

	    (else
	     (let ((new (valid? line field-delimiter)))
	       (if (error? new)
		   `(reader-error ,number ,new ,line)
		   (lp (cons new out) rest  valid? (+ 1
						      number)))))))))







