;; Necessary for generic procedures
(load (list "ps3/utils"
	    "ps3/collections"
	    "ps3/memoizers"
	    "ps3/predicates"
	    "ps3/predicate-metadata"
	    "ps3/predicate-counter"
	    "ps3/applicability"
	    "ps3/generic-procedures"))

;; Necessary for Parser
(load "task-parser.scm")
(load "file-reader.scm")

;; Necessary for Scheduler
(load "time-arith.scm")
(load "scheduler.scm")

;; Necessary for Illustrator
(load "graphics/util")
(load "graphics/io")
(load "graphics/element")


