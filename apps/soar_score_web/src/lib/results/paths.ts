/** Routes of the results pages (plan/ui/public-site/view-contest.md). */

export const resultsPath = "/results/contests";

/** `contestId` carries the publication id `GET /public/publications/{id}` is keyed by. */
export const contestResultsPath = (contestId: string, round?: number) =>
  round === undefined
    ? `${resultsPath}/${contestId}`
    : `${resultsPath}/${contestId}/rounds/${round}`;

export const contestTeamResultsPath = (contestId: string, round?: number) =>
  round === undefined
    ? `${resultsPath}/${contestId}/teams/results`
    : `${resultsPath}/${contestId}/teams/results/rounds/${round}`;

/** `?pilot=` names the pilot whose flight the view scrolls to. */
export const contestFlightGroupsPath = (contestId: string, round: number, pilotKey?: string) =>
  `${resultsPath}/${contestId}/rounds/${round}/flight-groups` +
  (pilotKey ? `?pilot=${encodeURIComponent(pilotKey)}` : "");

/** Disciplines whose flights carry a landing score; F3K has none. */
export const disciplineHasLanding = (disciplineType: string) =>
  ["F5J", "F3J", "ALES", "ThermalDuration"].includes(disciplineType);
