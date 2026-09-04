# RC Soar Score - Discipline Scoring Rules

The RC Soar Score solution is a set of applications and APIs to track, score, and publish results for radio controlled sailplane contests. These documents define the data points for determining the scoring of various disciplines.

All scoring disciplines have reasons for a pilot to receive a 0 score. The following are common to all disciplines:

* Out of bounds landing - The pilot landed too far from their landing marker. How this is described differs in each discipline.

Most soaring disciplines are scored by determining the pilot flying the longest within a given window or flying a prescribed amount of time followed by completing a precision landing. This is typically referred to as a "duration".

There are soaring disciplines where a pilot may need to complete more than one task within a round. The FAI F3B discipline has pilots complete a duration, speed, and distance task in a round to receive a round score.

There are variations on the duration task. In the FAI F3K discipline there are a pool of "tasks" that are available for a contest director to select. These tasks may require multiple flights to be recorded. As an example, a pilot may need to record their 5 best flight times and each of those flight times cannot be greater than 2 minutes long.

For the initial implementation and release of RC Soar Score the software will focus on simple disciplines where the goal is either to achieve the longest flight time within a give window or to fly a prescribed time. A landing bonus is given.

Contest disciplines using a simple duration only:

* [`ales.md`](./ales.md)
* [`f3j.md`](./f3j.md)
* [`f3l.md`](./f3l.md)
* [`f5j.md`](./f5j.md)
* [`thermal.md`](./thermal.md)

Contest disciplines using multiple types of a duration task:

* [`f3k.md`](./f3k.md)

*These are not initially implemented by RC Soar Score. They're included for informational purposes for design considerations.*

Contest disciplines using multiple tasks or tasks other than duration

* F3B
* F3F

*These are not initially implemented by RC Soar Score and are included here for informational purposes.*