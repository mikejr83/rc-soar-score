"use client";

import { useRouter } from "next/navigation";
import { useEffect } from "react";

import {
  contestFlightGroupsPath,
  contestResultsPath,
  contestTeamResultsPath,
  disciplineHasLanding,
} from "@/lib/results/paths";
import type { PublishedContest } from "@/lib/results/published-contest";

import { ContestHeader } from "./contest-header";
import { useContest } from "./contest-provider";
import { ContestLoadFailed, ContestNotFound, ContestNotVisible } from "./contest-states";
import { FlightGroupTable, flightRowId } from "./flight-group-table";
import { OverallResultsTable } from "./overall-results-table";
import styles from "./results.module.css";
import { RoundSelector } from "./round-selector";
import { Skeleton } from "./skeleton";
import { TeamResultsTable } from "./team-results-table";
import { ViewTabs, viewTitle, type ContestView as View } from "./view-tabs";

/**
 * A published contest's `view` as of `round`, or the latest round with
 * scores when undefined (plan/ui/public-site/view-contest.md). The contest
 * itself comes from the enclosing ContestProvider.
 */
export function ContestView({ view, round, pilotKey }: { view: View; round?: number; pilotKey?: string }) {
  const { contestId, result, reload } = useContest();
  const router = useRouter();
  const contest = result?.kind === "loaded" ? result.contest : undefined;
  const teamless = view === "teams" && contest !== undefined && !contest.hasTeams;

  // A team-less contest leaves the team view for the overall one.
  useEffect(() => {
    if (teamless) router.replace(contestResultsPath(contestId, round));
  }, [teamless, router, contestId, round]);

  // Scroll to the clicked pilot's flight once the groups are on the page.
  const shown = round ?? contest?.latestRound;
  useEffect(() => {
    if (view !== "flightGroups" || !pilotKey || !contest || shown === undefined) return;
    const group = contest.flightGroupsOf(shown).find((g) => g.flights.some((f) => f.isSelected && f.pilotKey === pilotKey));
    if (!group) return;
    document.getElementById(flightRowId(group, pilotKey))?.scrollIntoView({ block: "center" });
  }, [view, pilotKey, contest, shown]);

  if (!result || teamless) return <div className={`wrap ${styles.page}`}><Skeleton rows={8} header /></div>;
  if (result.kind === "notFound") return <div className={`wrap ${styles.page}`}><ContestNotFound /></div>;
  if (result.kind === "notVisible") return <div className={`wrap ${styles.page}`}><ContestNotVisible onRecheck={reload} /></div>;
  if (result.kind === "failed") return <div className={`wrap ${styles.page}`}><ContestLoadFailed message={result.message} onRetry={reload} /></div>;

  const path = (v: View, r: number) =>
    v === "overall" ? contestResultsPath(contestId, r)
    : v === "teams" ? contestTeamResultsPath(contestId, r)
    : contestFlightGroupsPath(contestId, r);

  return (
    <div className={`wrap ${styles.page}`}>
      <ContestHeader header={result.contest.header} />
      <div className={styles.viewBar}>
        <div>
          <p className="eyebrow">{viewTitle[view]}</p>
          <ViewTabs contestId={contestId} view={view} round={round ?? shown} hasTeams={result.contest.hasTeams} />
        </div>
        <RoundSelector rounds={result.contest.rounds} selected={shown} onChange={(r) => router.push(path(view, r))} />
      </div>
      {shown === undefined ? (
        <p className={`card ${styles.message}`}>No results have been published for this contest yet.</p>
      ) : (
        <Body contest={result.contest} contestId={contestId} view={view} round={shown} pilotKey={pilotKey} />
      )}
    </div>
  );
}

function Body({
  contest,
  contestId,
  view,
  round,
  pilotKey,
}: {
  contest: PublishedContest;
  contestId: string;
  view: View;
  round: number;
  pilotKey?: string;
}) {
  const empty = (text: string) => <p className={`card ${styles.message}`}>{text}</p>;
  switch (view) {
    case "overall": {
      const rows = contest.rowsAsOf(round);
      if (rows.length === 0) return empty(`There are no results for round ${round}.`);
      return <OverallResultsTable rows={rows} round={round} contestId={contestId} />;
    }
    case "teams": {
      const teams = contest.teamRowsAsOf(round);
      if (teams.length === 0) return empty(`There are no team results for round ${round}.`);
      return <TeamResultsTable teams={teams} round={round} contestId={contestId} />;
    }
    case "flightGroups": {
      const groups = contest.flightGroupsOf(round);
      if (groups.length === 0) return empty(`There are no flights for round ${round}.`);
      const hasLanding = disciplineHasLanding(contest.disciplineType);
      return (
        <>
          {groups.map((g) => (
            <FlightGroupTable
              key={`${g.group}-${g.reflight ?? 0}`}
              group={g}
              hasLanding={hasLanding}
              highlightPilotKey={pilotKey}
            />
          ))}
        </>
      );
    }
  }
}
