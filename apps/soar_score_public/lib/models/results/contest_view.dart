/// The views of a published contest (plan/ui/public-site/view-contest.md).
enum ContestView {
  overall('Overall Individual Results'),
  teams('Team Scores'),
  flightGroups('Flight Group Scores');

  const ContestView(this.title);

  final String title;
}
