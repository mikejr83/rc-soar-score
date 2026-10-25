import { describe, expect, test } from "vitest";

import { fakeSummary } from "./__fixtures__/fake-publication";
import { filtersFromQuery, filtersMatch, filtersToQuery } from "./contest-filters";
import { activeInLast30Days, contestSummaryFrom, startsAfterComingSunday } from "./contest-summary";

/** A Wednesday; the coming Sunday is 2026-10-18. */
const now = new Date(2026, 9, 14, 12);
const summary = (args: Parameters<typeof fakeSummary>[0]) => contestSummaryFrom(fakeSummary(args), now);

describe("contest list rules", () => {
  test("a contest starting on or before the coming Sunday is listed, after it hidden", () => {
    expect(startsAfterComingSunday(summary({ name: "Sat", start: new Date(2026, 9, 17, 9) }), now)).toBe(false);
    expect(startsAfterComingSunday(summary({ name: "Sun", start: new Date(2026, 9, 18, 9) }), now)).toBe(false);
    expect(startsAfterComingSunday(summary({ name: "Mon", start: new Date(2026, 9, 19, 9) }), now)).toBe(true);
  });

  test("derives the status from the end date and lets the projection win", () => {
    expect(summary({ name: "Done", start: new Date(2026, 9, 10, 9), end: new Date(2026, 9, 11, 17) }).status).toBe(
      "completed",
    );
    expect(summary({ name: "Flying", start: new Date(2026, 9, 13, 9), end: new Date(2026, 9, 15, 17) }).status).toBe(
      "inProgress",
    );
    expect(
      summary({
        name: "Scoring",
        start: new Date(2026, 9, 10, 9),
        end: new Date(2026, 9, 11, 17),
        status: "in_progress",
      }).status,
    ).toBe("inProgress");
  });

  test("the venue joins host, city, state and country", () => {
    expect(
      summary({ name: "V", start: now, host: "Club", city: "Dayton", state: "OH", country: "USA" }).venue,
    ).toBe("Club, Dayton, OH, USA");
  });

  test("the 30-day summary counts contests flown in the window", () => {
    const active = [
      summary({ name: "Recent", start: new Date(2026, 8, 14, 9), end: new Date(2026, 8, 15, 17) }),
      summary({ name: "Old", start: new Date(2026, 8, 12, 9), end: new Date(2026, 8, 13, 17) }),
      summary({ name: "Now", start: new Date(2026, 9, 14, 9), end: new Date(2026, 9, 14, 17) }),
      summary({ name: "Weekend", start: new Date(2026, 9, 17, 9) }),
    ].filter((c) => activeInLast30Days(c, now));
    expect(active.map((c) => c.name)).toEqual(["Recent", "Now"]);
  });
});

describe("filters", () => {
  const data = [
    summary({ name: "Contest Alpha", start: new Date(2026, 9, 10, 9), city: "Dayton" }),
    summary({ name: "Contest Beta", start: new Date(2026, 9, 3, 9), city: "Muncie" }),
    summary({ name: "Contest Gamma", start: new Date(2026, 8, 20, 9), city: "Dayton" }),
  ];
  const names = (query: string) =>
    data.filter((c) => filtersMatch(filtersFromQuery(new URLSearchParams(query)), c)).map((c) => c.name);

  test("name and venue filters match case-insensitively", () => {
    expect(names("name=be")).toEqual(["Contest Beta"]);
    expect(names("venue=dayton")).toEqual(["Contest Alpha", "Contest Gamma"]);
  });

  test("the start-date range is inclusive and bookmarks restore", () => {
    expect(names("from=2026-10-03&to=2026-10-10")).toEqual(["Contest Alpha", "Contest Beta"]);
    expect(names("name=alpha&venue=day&from=2026-10-01")).toEqual(["Contest Alpha"]);
  });

  test("the query round-trips without unset filters", () => {
    const f = filtersFromQuery(new URLSearchParams("name=alpha&from=2026-10-01&to="));
    expect(filtersToQuery(f).toString()).toBe("name=alpha&from=2026-10-01");
  });
});
