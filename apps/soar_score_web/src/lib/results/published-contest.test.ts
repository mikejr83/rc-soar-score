import { describe, expect, test } from "vitest";

import { fakePublication } from "./__fixtures__/fake-publication";
import { formatTime } from "./format";
import { contestFlightGroupsPath, contestTeamResultsPath } from "./paths";
import { PublishedContest, ScoreFields, detailKeys, groupTitle, hasRawComponents, headerStatus } from "./published-contest";

const contest = new PublishedContest(fakePublication(), new Date(Date.UTC(2026, 9, 12)));

describe("overall results", () => {
  test("rounds come from the standings and the latest is the default", () => {
    expect(contest.rounds).toEqual([1, 2, 3]);
    expect(contest.latestRound).toBe(3);
    expect(contest.rowsAsOf(9)).toEqual([]);
  });

  test("status derives from the end date until the projection carries it", () => {
    expect(contest.header.isCompleted).toBe(true);
    const running = new PublishedContest(fakePublication(), new Date(Date.UTC(2026, 9, 10, 15)));
    expect(headerStatus(running.header)).toBe("In progress");
    const stated = new PublishedContest(fakePublication({ contestStatus: "Running" }), new Date(Date.UTC(2027, 0)));
    expect(headerStatus(stated.header)).toBe("In progress");
    expect(contest.header.venue).toBe("Front Range Soaring, Boulder, CO, USA");
  });

  test("as of round 2 nothing is dropped and ties sort by last name", () => {
    const rows = contest.rowsAsOf(2);
    expect(rows.map((r) => r.lastName)).toEqual(["Smith", "Adams", "Baker", "Waters"]);
    expect(rows.map((r) => r.place)).toEqual([1, 2, 2, 4]);
    expect(rows[1].isTied).toBe(true);
    expect(rows[3].droppedRounds.size).toBe(0);
    expect([...rows[3].roundScores]).toEqual([
      [1, 900],
      [2, 990],
    ]);
    expect(rows[3].percentOfWinner).toBeCloseTo(94.5, 1);
  });

  test("as of round 3 the dropped round and penalty show", () => {
    const rows = contest.rowsAsOf(3);
    expect(rows.map((r) => r.lastName)).toEqual(["Smith", "Baker", "Waters", "Adams"]);
    const waters = rows[2];
    expect([...waters.droppedRounds]).toEqual([1]);
    expect([...waters.roundScores.values()]).toEqual([900, 990, 990]);
    expect(waters.penaltyTotal).toBe(50);
    expect(waters.rawTotal).toBe(2030);
  });
});

describe("team results", () => {
  test("contestTeamResultsPath builds both route shapes", () => {
    expect(contestTeamResultsPath("abc")).toBe("/results/contests/abc/teams/results");
    expect(contestTeamResultsPath("abc", 2)).toBe("/results/contests/abc/teams/results/rounds/2");
  });

  test("team rows rank teams and list their pilots by place", () => {
    expect(contest.hasTeams).toBe(true);
    const teams = contest.teamRowsAsOf(3);
    expect(teams.map((t) => t.name)).toEqual(["Eagles", "Hawks"]);
    expect(teams[0].teamScore).toBe(5846);
    expect(teams[1].percentOfWinner).toBeCloseTo(85.08, 1);
    expect(teams[0].pilots.map((p) => p.lastName)).toEqual(["Smith", "Adams"]);
    expect(teams[1].pilots.map((p) => p.lastName)).toEqual(["Baker", "Waters"]);
    expect(contest.teamRowsAsOf(9)).toEqual([]);
    expect(new PublishedContest(fakePublication({ teams: false })).hasTeams).toBe(false);
  });
});

describe("flight groups", () => {
  test("contestFlightGroupsPath carries the round and the pilot", () => {
    expect(contestFlightGroupsPath("abc", 2)).toBe("/results/contests/abc/rounds/2/flight-groups");
    expect(contestFlightGroupsPath("abc", 2, "waters")).toBe(
      "/results/contests/abc/rounds/2/flight-groups?pilot=waters",
    );
  });

  test("flight groups keep every flight and split out the re-flight", () => {
    const groups = contest.flightGroupsOf(3);
    expect(groups.map(groupTitle)).toEqual(["Group 1", "Group 2", "Group 2, re-flight 1"]);
    expect(groups[1].flights.map((f) => f.groupScore)).toEqual([850, 400]);
    expect(groups[1].flights[1].isSelected).toBe(false);
    expect(groups[2].flights).toHaveLength(1);
    expect(groups[2].flights[0].pilotKey).toBe("waters");
    expect(detailKeys(groups[2])).toEqual(["launch_height"]);
    expect(hasRawComponents(contest.flightGroupsOf(1)[0])).toBe(false);
    expect(contest.flightGroupsOf(9)).toEqual([]);
  });

  test("score fields label the raw columns and fall back to the key", () => {
    const { scoreFields } = contest;
    expect(scoreFields.label("launch_height")).toBe("Launch Height (m)");
    expect(scoreFields.label("late_landing")).toBe("Late landing");
    expect(scoreFields.format("launch_height", 200)).toBe("200");
    expect(scoreFields.format("launch_height", null)).toBe("-");
    expect(scoreFields.format("late_landing", true)).toBe("true");
  });

  test("a precision outside what toFixed accepts shows the value as is", () => {
    const fields = new ScoreFields(
      new Map([
        ["huge", { name: "Huge", precision: 101 }],
        ["edge", { name: "Edge", precision: 100 }],
      ]),
    );
    expect(fields.format("huge", 1.5)).toBe("1.5");
    expect(fields.format("edge", 1.5)).toHaveLength(102);
  });

  test("times format as minutes and seconds", () => {
    expect(formatTime(600)).toBe("10:00");
    expect(formatTime(598.8)).toBe("9:58.8");
    expect(formatTime(null)).toBe("-");
  });
});
