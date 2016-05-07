# 6.945: Scheduler Write-Up

## Overview
This section of the program:

- Creates Tasks, instants, and durations of time
- Uses dependencies and a scheduling heuristic to calculate task order
- Builds a schedule consisting of a list of "work blocks"

The scheduler iteratively solves the "knapsack problem" with the added constraint that after a Task is fully completed, new Tasks may become available according to the dependency tree.  It also allows the user to customize how many hours of work happen per day of the week, how regularly they want a break (e.g. 15 minutes of break per 3 hours of work), and the maximum amount of time they want to spend on any task on a given day.  

## Interface

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


## Time Arithmetic

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

## Scheduling Heuristic & Algorithm

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
 
The scheduler iteratively performs this process until all of the tasks added at the outset have been scheduled into a list of work blocks and then returns them for the visualizer.
