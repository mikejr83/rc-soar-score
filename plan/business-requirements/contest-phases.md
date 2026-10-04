# RC Soar Score Business Requirements

The RC Soar Score solution is a set of applications and APIs to track, score, and publish results for radio controlled sailplane contests. Management of the contest is included a web application used in online access. The application is also wrapped in a desktop shell for use when there is no internet or as desired by the contest director.

The contest director will use an application to create, configure, and run contests. There are a number of steps that must be performed before a contest is considered created and ready to start. This document covers a high-level view of how a contest occurs.

1. Initialization - Covered in the **Creating New Contests** section of the `managing-system.md` file.
2. Configuration - Covered in the `contest-configuration.md` file.
3. Matrix creation - Covered in the `contest-draw.md` file.
4. In progress - The contest is running. Pilots or their helpers are entering scores as described in `contest-self-scoring.md` if it is enabled or an official is entering scores manually.
5. Completed - The contest is over. Scores are entered.

## Initialization

A contest director will "create" a new contest. This involves the basic selection of a "New Contest" or some other such action and entering in the required details. A contest may sit in this state but it isn't able to have a draw created or scores entered. Basically, the contest has had its initial data entry created but nothing else about the contest has been defined.

## Configuration

The contest director has performed the initial creation of the contest and is now configuring the details of the contest. This includes items such as the class/discipline of the contest, the participants, scoring options, etc. A contest director may have a contest in this state for some time. As pilots register and are added to the contest the director may come back and add them to the participation. The contest director may decide to change different configuration parameters as the time nears for the contest to be held.

## Matrix Creation

The number of rounds to be flown in the contest is decided and the pilots are organized into groups. This is performed by performing a draw on the pilots for each group. The groups in the rounds and the pilots participation in those groups makes up the flight matrix.

Once a flight matrix has been generated scores can be entered.

A contest can be considered started once the first scores have been entered for the first group of the first round.

## Started or In Progress

At this point the contest is underway. Scores have been entered and the contest is progressing. Participants or officials are entering scores. Participants will be entering the scores using the web application. Officials will be entering scores using a specialized official screen in the management application either through the web or the desktop version.

Once a contest underway the logic flow for the contest is:

1. A round is started
2. The first group in the round competes.
3. The group concludes its flights and scores are noted either immediately in the app or on a piece of paper.
4. The next group competes.
5. Steps 2-4 are repeated until all the groups for the round have flown.
6. After the last group it is ideal that pilots enter their scores before the next round starts.
7. The next round starts.

Rounds and groups fly sequentially. Scores should be entered sequentially, however, some pilots may forget to enter a their score after their group's completion. Therefore, there will be some pilots entering scores on a timely basis and others that are lagging. It is highly unlikely that a pilot would enter future scores. This could be detected by seeing that one pilot is entering data in rounds more than one of the rest of all the other pilots. However, consideration still has to be given that the first pilot entering scoring data after the completion of the first group in the round will now be at least one ahead of all other pilots and may be more rounds ahead than those lagging in entering their scores.

## Completed

A contest can be completed/finished in a number of conceptual ways:

- If all the groups for all the rounds in the matrix have a score (or indication that a zero score is recorded) for each pilot that has not retired.
- No score has been entered in 48 hours.
- The contest director has marked the contest as completed.

Often contest directors will configure a contest with a matrix for more rounds than they intend to fly. This is done out of optimism. The contest will continue until some point without all the rounds being completed. A pilot may drop out, retire, and thus have for some number of rounds while other pilots still fly. Thus it is difficult to objectively look at the data and declare the contest over. The points above give a solid indication of the contest being completed.

An assumption can be made that the contest is completed with the following conditions:

- All rounds where any pilot has a score also has a score for all other pilots
- All rounds where any pilot has a score are only missing scores for pilots that have retired.

It is only an assumption because the contest director may be instructing the pilots to actively complete their scoring before the next round starts. Thus, if the assumption was made in round 7 of a 9 round contest, the contest may not be over, but the contest director is making sure that everyone is aware of their placing before entering the last two rounds.
