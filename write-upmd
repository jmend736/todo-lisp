# todo-lisp
An illustrated task scheduler written in MIT/GNU Scheme for the Spring 2016 offering of [6.945: Adventures in Advanced Symbolic Programming](https://groups.csail.mit.edu/mac/users/gjs/6.945/) by:

- Geoffrey Gilmore <<ggilmore@mit.edu>>
- John O'Sullivan <<johno@mit.edu>>
- Julian Mendoza <<jmend@mit.edu>>

## Table of Contents
 1. Parser
	 2. Overview
	 3. Interface
	 3. Schedule Options
	 3. Task Parsing
 3. Scheduler
	 1. Overview
	 2. Interface
	 3. Time Arithmetic
	 4. Scheduling Heuristic & Algorithm
 4. Illustrator
	 1. Overview
	 2. Interface
	 3. Generic Elements
	 4. Combination of Elements
	 5. Output

## Parser

### Overview

This part of the program is responsible for parsing a user's given
representation for a collection of __tasks__, validating them, and
packaging all this information up so that it the rest of the project can use it.

### Interface

In our system, an individual _task_ is described (loosely) in the following manner:

```scheme
('task
    ('id <id>)
    ('description <description>)
    ('duration <duration>)
    ('deadline <deadline>)
    ('duration <duration>)
    ('dependencies <dependencies>))
```
You can read the program technical specification for more specifics,
but here's a brief description of each of the fields:


| Field Name       | Field Description                                                                                                           | Example                                                                                              |
|------------------|-----------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------|
| `<id>`           | unique integer identifier for a task                                                                                        | `22`                                                                                                 |
| `<description>`  | description of a task                                                                                                       | `"This is not The Greatest Task in the World, no. This is just a tribute..."`                        |
| `<deadline>`     | string time representation that represents the fixed moment in time that a task must be completed by (`"YYYY-MM-DD-HH-MM"`) | `"1958-09-09-11-58"` <- This creates a deadline for the task that is September 9th 1958, at 11:58 AM |
| `<duration>`     | string time representation for how long a given task is supposed to last (`"XXd-XXh-XXm"`)                                  | `"11d-22h-63m"` <- This makes a task with a duration of 11 days, 22 hours, and 63 minutes.               |
| `<dependencies>` | Comma delimited list of integer ids (possibly empty) of the tasks that must be completed before this task can be started    | `22, 44`                                                                                             |

### Schedule Options
A user is also able to define _schedule options_, which allows the user to the number of hours they are able to work on any given day of the week, etc.

```scheme
('schedule-options
    ('hours-per-day <hours-per-day>)
    ('time-per-task <time-per-task>)
    ('break-interval <break-interval>))
```
|    Option Name     |                                                      Option Description                                                       |            Example
:------------------:|:-----------------------------------------------------------------------------------------------------------------------------:|:-----------------------------:
 `<hours-per-day>`  | 7 element list with time element strings, representing the amount of hours that you want to work on any given day of the week | `"8h, 8h, 5h, 3h, 2h, 0h, 0h"`
 `<time-per-task>`  | String time representation of the maximum amount of time per day that you want to spend doing a particular task (`"XXh-XXm"`) |          `"03h-15m"`
`<break-interval> ` |         string time representation of how long of a break the user wants in between work "chunks" (`"XXm-every-XXh"`)         |       `"45m-every-09h"`


### Task Parsing

The "official" method for specifying a list of tasks is just to write a plain text file. Individual tasks are separated by newlines, and the individual fields for any given task are separated by a configurable delimiter.

Example of a text file of schedule options, followed by 2 tasks (delimiter == `#!`):

```


8h, 8h, 5h, 3h, 2h, 0h, 0h #! 03h-15m #! 45m-every-09h
--BEGIN--
1 #! task 1 depends on task 2  #! 1958-09-09-11-58 #! 11d-22h-63m #! 2
2 #! task 2 depends on nothing #! 1958-09-09-01-40 #! 00d-00h-30m #!


```

Even though the above is the "official" method of specifying tasks, the parser uses good style, and abstracts the specifics of grabbing the individual fields of each task/schedule option to function calls:


```scheme

;;emulates python's split() function
;;"1,23,3" -> ("1" "23" "3")
(define (parser:split line delimiter)
  ...)

(define (parser:task:id t)
  (cadr t))

(define (parser:task:description t)
  (caddr t))

(define (parser:task:duration t)
  ...)

...

```

Nothing is preventing the system from supporting other file formats, such as `JSON`.


```json
{
    "id": 22,
    "description": "this is a JSON example",
    "duration": "...",
    ...
}
```

This part of the program does not employ generic operators or pattern matching. The task / schedule option schema is (deliberately) simple and tightly defined, and so the power/flexibility offered by both of these systems is not necessary. In this case, these systems would introduce unnecessary overhead/complexity, and would negatively affect the readability of the program.

After the whole file is parsed, each individual task is handed off to the validator:

```scheme
(define (parser:valid:task? candidate task-delimiter)
  (let ((args (parser:readline args task-delimiter)))
    (and (eq? 6 (length args))
	 (parser:valid:id? (parser:task:id candidate))
	 (parser:valid:description? (parser:task:description
				     candidate))
	 (parser:valid:duration? (parser:task:duration candidate))
	 (parser:valid:deadline? (parser:task:deadline candidate))
	 (parser:valid:dependencies? (parser:task:dependencies
				      candidate)))))
```

As you can see above, the each individual field of the task is passed to off to individual "sub" validators:

Examples:

```scheme
(define (parser:valid:id? candidate)
  (integer? (string->number candidate)))

(define (parser:valid:description? candidate)
  ...)

  (define (parser:valid:time-arg? candidate interval)
    (if (not (and (string? interval)
  		(> (string-length interval) 0)))
        (error "parser:valid:time-arg? -> Interval must be a string and have a length > 0")
        (and (string? candidate)
  	   (>= (string-length candidate) 2)
  	   (string-search-backward interval candidate)
  	   (integer?
  	    (string->number (string-head candidate
  					 (- (string-length
  					     candidate)
  					    (string-length
  					     interval))))))))

(define (parser:valid:duration? candidate)
  (and (string? candidate)
       (let ((args (parser:readline candidate "-")))
	 (pp args)
	 (and (eq? 3 (length args))
	      (parser:valid:time-arg? (car args) "d")
	      (parser:valid:time-arg? (cadr args) "h")
	      (parser:valid:time-arg? (caddr args) "m")))))
...
```

If any particular task is unable to be parsed, the whole read-file operation fails, and the user is informed as to which field was incorrectly specified. Otherwise, the tasks are all packaged up in simple scheme lists and handed off to the other parts of the program. 

## Scheduler

### Overview

This section of the program:

- Creates Tasks, instants, and durations of time
- Uses dependencies and a scheduling heuristic to calculate task order
- Builds a schedule consisting of a list of "work blocks"

The scheduler iteratively solves the "knapsack problem" with the added constraint that after a Task is fully completed, new Tasks may become available according to the dependency tree.  It also allows the user to customize how many hours of work happen per day of the week, how regularly they want a break (e.g. 15 minutes of break per 3 hours of work), and the maximum amount of time they want to spend on any task on a given day.  

### Interface

The scheduler exposes three main functions for building a schedule: `add-task`, `set-settings`, and `get-schedule`.

```scheme
(add-task <id> <description> <duration> <deadline> <dependencies>)
```
`add-task`:

1. Accepts integer ids, strings for description/duration/deadline, and a list of integer ids for dependencies.
2. Converts the duration and deadline into the internal time representation.
3. Creates the Task object as specified.
4. If the Task has no dependencies, it's added to the internal `available-tasks` hash table --- otherwise, `blocked-tasks`.

```scheme
(set-settings <hours-per-day> <time-per-task> <break-interval>)
```
`set-settings`:

1. Parses the string arguments into internal time objects. 
2. Stores the resulting values in globally available config variables which get queried while building the schedule.

```scheme
(get-schedule)
```
`get-schedule` is a thunk which analyzes all tasks which have been added and uses the "knapsack" algorithm to build and return a list of appropriately sized work blocks which each represent one duration of work on a given task (i.e. a single task may get mapped into multiple work blocks).

### Time Arithmetic

One preliminary problem which needed solving was easily adding and subtracting dates and durations of time.  If the scheduler is currently at 3:00pm on May 15th and we add a two hour work block, what will the new current time be?  Out of the box, Scheme doesn't have a description for a duration of time.  

Scheme's three representations of time are:

- Universal time, number of seconds since January 1st, 1900.
- Decoded time, a human-readable representation with field accessors.
- File time, an OS-specific timestamp we didn't use.

We defined two generic operators, `t+` and `t-`, which allow for the addition and subtraction of `instants` and `durations`.  An instant is essentially a wrapper over a Scheme `decoded-time`, while a duration is an association list of integer values for days, hours, and minutes.  While we also could've extended built-in arithmetics, this approach seemed lighter-weight given that we only need addition and subtraction on two new types.

```scheme
(t+ left right)
```

- `(t+ <duration> <duration>)`: Returns a new duration whose length is the sum of the original two.
- `(t+ <duration> <instant>)`: Returns a new instant which is `duration` further in the future from the original one.
- `(t+ <instant> <instant>)`: Throws an error, the sum of two dates doesn't make any intuitive sense.

```scheme
(t- left right)
```

- `(t- <duration> <duration>)`: Returns a new duration of length `longerDuration - shorterDuration` (automatically checks which is larger).
- `(t- <duration> <instant>)`: Returns a new instant which is `duration` further back in the past from the original one.
- `(t- <instant> <instant>)`: Returns a new duration which is the amount of time between the two instants.

Under the hood, these operations are performed by 

1. Converting durations into an integer number of seconds.
2. Converting instants via `decoded-time->universal-time`.
3. Performing all math on second values.
4. Converting back in both directions at the end.

### Scheduling Heuristic & Algorithm

In order to apply the "knapsack problem" to the task scheduling problem, each task needs to have a weight and a value.  Intuitively, the weight of a task is its duration (or the duration remaining).  The value, however, is less obvious.  We decided to use a metric which models urgency: `<work-hours-remaining-until-task-deadline> - <task-duration>`.  `<work-hours-remaining-until-task-deadline>` is calculated by summing the available hours over all of the days until the deadline (i.e. `(* <hours-per-task-per-day> <number-days>)`).

Each time the system calculates a new work block, it checks the value of this metric for all of the available tasks and then selects the one with the smallest value.  If the value were ever negative, for instance, that would mean a task is going to be late given its deadline, duration, and constraints.  The task with the smallest value is the most urgent and is assigned the next work block.

For each selected task, the scheduler:

1. Calculates `(min (min <remaining-daily-hours> <task-duration>) <time-remaining-in-interval>)`.
2. Decrements the task's saved duration by the resulting amount.
3. Creates and schedules a new work block of that same duration.  
 
If the selected task is going to be late, the scheduler checks if it could be completed by disregarding the `<hours-per-task-per-day>` option.  If so, it recalculates work blocks without keeping daily work on that task beneath the preconfigured level and lets the user know via log statements.  If the task still cannot be completed on time, the scheduler proceeds and lets the user know one of their tasks will be late.

After completing a task (i.e. creating enough work blocks that its duration is now 0), the scheduler:

1. Adds the task to the `completed-tasks` hash table.
2. Scans the `blocked-tasks` hash table to find tasks whose dependencies are all contained in `completed-tasks`.
3. If any are found, it removes them from `blocked-tasks` and adds them to `available-tasks`.
 
The scheduler iteratively performs this process until all of the tasks added at the outset have been scheduled into a list of work blocks and then returns them for the illustrator.

## Illustrator

### Overview

This block of the program is responsible for taking input from the task schedule, as a list of dependencies, and generating graphviz dot files to display the schedule.

The goal of the graphics block will be to accomplish this task with few limitations on the format of the input. To do this, it will work on generic elements which the user will be able to define. If another format of input is desired, simple changes to the input are all that's needed.

### Interface

The input for the graphics block will be an association list with the work blocks and a specified format. The format will be built using generic elements. To define a format you must define the generic elements and pass both the format and elements into the function.

```scheme
;; To define a generic element
; predicate: checks whether passed element is of correct format
; return: function to be called with element to extract information
(d:generic-element predicare return)
```
given that a work block has this format
```scheme
('workblock
    ('block_id <id>)
    ('dependent_ids <dependencies>)
    ('description <description>)
    ('taskid <taskid>)
    ('duration <duration>)
    ('starttime <deadline>)
    ('deadline <deadline>)
    ('duration <duration>))
```

we would have to define generic elements for `blockid`, `dependent_ids`, `description`, etc. so an example format might look something like
```scheme
(d:block_id d:dependent_ids d:description ...)
```
where each of these are generic elements passed as a list.

| Field Name      | Field Description                                   | Example             |
| ----------      | -----------------                                   | -------             |
| `block_id`      | The ID for this specific work block                 | `2320`              |
| `dependent_ids` | A list of the IDs that depend on this element       | `'(2032 0329 9402)` |
| `taskid`        | The ID for the task that this work block belongs to | `4932`              |
| `starttime`     | The date and time that a task is scheduled to begin | `"0d-3h-10m"`       |

Note: Much of this is discussed more thoroughly earlier in the Parser section.

### Generic Elements

As discussed before generic elements are defined using
```scheme
(d:generic-element predicare return)
```
here they key take function is the `return` function. This is what decides how the element behaves and what it will be used for. For example, for dot to work, each of the blocks must have their own unique id (this is what the `block_id`) is, and we define a special generic element. The `return` function will return an element, which is a list where the first item is a `symbol` representing the type of element and next blocks are used for data. The identifying `symbol` is used by the assembler to know how to use the element.

There are three general types of elements:

#### Base Elements
These are used as the names for nodes in dot. These are the base for the graph.

#### Option Element
These are options that are added onto nodes or edges on the graph. These will typically be different properties that are applied to the graph (such as style properties like color, etc).

#### Multiple Elements
These are properties which will require processing more than one elements'. An example of this is rank, as we'll need to group all of the similarly ranked elements into one block.

### Combination of Elements

Combination is a matter of processing them into a graph format
```scheme
('graph (('linename1 ...) ('linename2 ...) ...))
```
The graph would be a linked list where each element is a named line to be generated in the final output.

This format allows for generation to be simple, to create a new edge, we can simply create a new element in the graph alist. The other case, if we want to edit or append something to an element, we can search the graph alist, and edit that element individually.

This is supposed to be internal, but extending this to add new features is straightforward, as you simply need to define the function that will edit the graph for a specific element.

### Output

The final output is generated by converting the `graph` object into a string and writing that to a file. Then I run a terminal command to generate the final product.

The code for writing the file and running the terminal code are based on to that used in the problem sets.