;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;                               todo-lisp
;;
;; Filename: graphics.scm
;;
;; Description:
;;          Base for graphics block of project
;;
;; Functions:
;;          ((d:factory [format]) [input list] [filename])
;;              - Will generate .dot file and .ps from that .dot file
;;
;;
;; Author: jmend
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Base function to be called to generate output
;; Will write a .dot file and then run dot on it to generate .ps file
(define (d:factory format #!optional options)
  (if (eq? options #!default)
    (d:factory format default-options)
    (lambda (assl filename)
      (if (d:check-format format assl)
        (let lp ((graph (d:init-graph))
                 (converted (d:convert format assl)))
          (if (null? converted)
            (write-dot-file (d:graph->str graph options assl) filename)
            (lp (d:elem->graph (car converted) graph) (cdr converted))))
        (error "d:factory: assl format error")))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                   Format we're using
;('workblock
;    ('block_id <id>)
;    ('dependent_ids <dependencies>)
;    ('description <description>)
;    ('taskid <taskid>)
;    ('duration <duration>)
;    ('starttime <deadline>)
;    ('deadline <deadline>))

;; Generic Elements
;   - start : '(start <symbol>)
;   - end : '(end <symbol>)
;   - props : '(props (option_name value))
;   - nprops : '(nprops (option_name <node> value))
;   - special : '(special <anything>)

;; Generic Elements used for our project

;; The current workblock
(define d:blockid
  (d:generic-element (lambda (x) (and (pair? x) (eq? (car x) 'block-id)))
                     (lambda (x) (list 'end (list (cadr x))))))


;; The workblocks that need to be done before the current one
(define d:dependentids
  (d:generic-element (lambda (x) (and (pair? x) (eq? (car x) 'dependent-ids)))
                     (lambda (x) (list 'start (if (pair? (caadr x))
                                                (caadr x)
                                                (if (not (null? (caadr x)))
                                                  (cadr x)
                                                  (list d:nothing)))))))

;; Used to align the elements with the times subgraph
(define d:starttime
  (d:generic-element (lambda (x) (and (pair? x) (eq? (car x) 'start-time)))
                     (lambda (x) (list 'special (list (cadadr x))))))

;; A description that goes in the nodes
;; Appending quotes else graphviz gets sad :(
(define d:description
  (d:generic-element (lambda (x) (and (pair? x) (eq? (car x) 'description)))
                     (lambda (desc)
                       (list 'nprops (list "label" 'end (string-append "\"" (cadr desc) "\""))))))

;; Unused element of the input
(define d:unused
  (d:generic-element (lambda (x) #t) (lambda (x) #f)))


;; Final Format
(define final-format (list d:blockid d:dependentids d:description
                           d:unused d:unused d:unused d:unused))

