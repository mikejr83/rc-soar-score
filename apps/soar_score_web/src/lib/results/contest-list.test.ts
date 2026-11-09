import { describe, expect, test } from "vitest";

import { fakeSummary } from "./__fixtures__/fake-publication";
import { filtersFromQuery, filtersToQuery, listQuery } from "./contest-filters";
import { contestSummaryFrom } from "./contest-summary";

/** A Wednesday; the coming Sunday is 2026-10-18. */
const now = new Date(2026, 9, 14, 12);
const summary = (args: Parameters<typeof fakeSummary>[0]) => contestSummaryFrom(fakeSummary(args), now);

describe("contest list rules", () => {
  test("derives the status from the end date and lets the projection win", () => {
    expect(summary({ name: "Done", start: new Date(2026, 9, 10, 9), end: new Date(2026, 9, 11, 17) }).status).toBe(
      "completed",
    );
    expect(summary({ name: "Flying", start: new Date(2026, 9, 13, 9), end: new Date(2026, 9, 15, 17) }).status).toBe(
      "inProgress",
    );
    expect(summary({ name: "Soon", start: new Date(2026, 9, 20, 9), end: new Date(2026, 9, 21, 17) }).status).toBe(
      "upcoming",
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

  test("the discipline comes from the summary, empty when it carries none", () => {
    expect(summary({ name: "D", start: now, discipline: "F5J" }).discipline).toBe("F5J");
    expect(summary({ name: "D", start: now }).discipline).toBe("");
  });
});

describe("filters", () => {
  test("the list query carries the filters, the viewer's day and the page size", () => {
    const empty = listQuery(filtersFromQuery(new URLSearchParams("")), new Date(2026, 10, 1, 21));
    expect(empty.toString()).toBe("today=2026-11-01&limit=10");

    const filtered = listQuery(
      filtersFromQuery(new URLSearchParams("name=alpha&venue=day&from=2026-11-06&to=2026-11-09")),
      new Date(2026, 10, 2, 9),
    );
    expect(Object.fromEntries(filtered)).toEqual({
      name: "alpha",
      venue: "day",
      from: "2026-11-06",
      to: "2026-11-09",
      today: "2026-11-02",
      limit: "100",
    });
  });

  test("the query round-trips without unset filters", () => {
    const f = filtersFromQuery(new URLSearchParams("name=alpha&from=2026-10-01&to="));
    expect(filtersToQuery(f).toString()).toBe("name=alpha&from=2026-10-01");
  });
});
