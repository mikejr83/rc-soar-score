# RC Soar Score Business Requirements

The RC Soar Score solution is a set of applications and APIs to track, score, and publish results for radio controlled sailplane contests.

Sailplane contests are events where participants gather to test their skills in radio controlled soaring disciplines. The job of this solution is to managing the setup, running & participation, and publishing of results.

Broadly, sailplane contests have a contest director and a number of pilots participating. The contest director is responsible for setting up the parameters of the contest: the discipline to be flown, rules for scoring, and how pilots will compete against each other. Pilots compete against one another to receive scores. A pilot, a helper, or an official enters their scores.

The following individuals participate in a contest:

* Contest director - This is the organizer of the contest. They are responsible for configuring the contest, ensuring scores are entered, and that the contest runs according to the rules specific to the contest discipline.
* Official - A term synonymous with the contest director when referring to administrative score entry or review. Another person may help perform these actions on the same device and offline installation, but the application does not treat that person as a separate official user type.
* Pilot - This individual receives scores for flying in the contest.
* Helper - These individuals are associated to a pilot when the contest features teams. They are tracked for cataloging and reporting. They also can enter scores on behalf of pilots on their team.

A contest is divided up into a number of rounds. Pilots are placed into groups within each round. Each group is flown with their pilots. A pilot receives a single overall score for the round. How this score is computed depends on different factors.

Some disciplines may need to complete multiple tasks per round. These tasks receive scores which would make up the overall round score for a pilot. The initial versions of RC Soar Score will focus only on soaring disciplines which only have one task per round.

Depending on the discipline, a pilot's round score may reflect individual components, eg time in the air, landing bonus, etc.. The discipline type will dictate what score components are recorded. The contest configuration along with the discipline determines how scores are computed.

The phases of a contest are outlined in `contest-phases.md`. Once a contest has started the pilots or their helpers interact with the contest as described in `contest-self-scoring.md`. A contest can be scored administratively by the contest director, or by a local operator working under the director's authority on the same installation. This process is covered in `contest-official-scoring.md`.
