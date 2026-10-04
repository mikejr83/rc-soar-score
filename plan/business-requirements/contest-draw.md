# RC Soar Score Business Requirements

The RC Soar Score solution is a set of applications and APIs to track, score, and publish results for radio controlled sailplane contests. Management of the contest is included a web application used in online access. The application is also wrapped in a desktop shell for use when there is no internet or as desired by the contest director.

This document will use the terms "draw" and "matrix". Generally, the term "draw" is referred to the process of placing the pilots into groups for each of the rounds. The term "matrix" is used to define the final allocation of pilots to groups in the contest.

The pilots must be organized into groups within a number of rounds before the contest is started. The contest configuration contains the basic options used in the selection of pilots into groups. The goal of this process is to achieve the following:

- Create a "flight matrix" that places pilots into groups for each round of the contest.
- Create a fair distribution of opportunities for each pilot to fly against another pilot.

The contest director needs to provide how many rounds which will be flown in the contest. Additionally, a contest director may wish to add rounds or redraw rounds where a matrix already exists.

Initially, the contest director provides the number of rounds to be flown and a draw is performed. The actual process of how pilots are allocated is not important, but the outcome where a pilot flies against as many different pilots as possible is desirable. To this end, the process should be evaluated for fairness. A summary of this should be presented to the contest director.

The contest director should be able to look at this indicator of fairness at any point once a draw is completed.

## Post Draw Scenarios

Contest directors are generally optimistic about how many rounds may be flown in a contest. For instance, a contest director may think 16 rounds can be performed over two days when they may actually only get 12. However, the contest director may select too few rounds initially and wish to add more. The application should let them add rounds to the matrix and complete a draw for those rounds.

A contest director may change certain contest configuration options after a draw is performed (the discipline cannot be changed once set). The application should warn the contest director of any changes which would affect the the matrix. The contest director should then have the option to perform a re-draw to create a new matrix.

If a pilot was added after a draw was made it should be alerted to the contest director that the pilot was randomly added to the existing groups over the rounds. A new draw is advisable.

Once scores have been entered the draw is locked. A pilot who arrives late can still be added by the contest director. The pilot flies in groups that have not yet flown, in the current or later rounds, and may fly more than once to make up rounds they missed. This is at the contest director's discretion. Any round the pilot does not make up counts as a zero. A pilot can be added only if groups in the remaining rounds have space for them, up to the largest group size of the original draw. If there is no space, the application tells the contest director that no group is available for the pilot. It may offer to redraw the later rounds, but that is the contest director's decision, because pilots' printed matrix cards for the redrawn rounds would have to be reprinted. Cards for rounds that are not redrawn stay valid.
