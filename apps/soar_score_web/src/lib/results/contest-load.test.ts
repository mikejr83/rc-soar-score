import { afterEach, describe, expect, it, vi } from "vitest";

import { fakeContestId, fakePublication } from "./__fixtures__/fake-publication";
import { loadContest } from "./contest-load";

function answer(status: number, body: unknown) {
  vi.stubGlobal(
    "fetch",
    vi.fn(async () => new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } })),
  );
}

afterEach(() => vi.unstubAllGlobals());

describe("loadContest", () => {
  it("parses a served publication", async () => {
    answer(200, fakePublication());
    const result = await loadContest(fakeContestId);
    expect(result.kind).toBe("loaded");
    if (result.kind === "loaded") expect(result.contest.latestRound).toBe(3);
  });

  it("treats a malformed id as not found without a request", async () => {
    const fetchSpy = vi.fn();
    vi.stubGlobal("fetch", fetchSpy);
    expect(await loadContest("private")).toEqual({ kind: "notFound" });
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it("maps 404 to not found and 403 contest_not_visible to not visible", async () => {
    answer(404, { error: { code: "not_found", message: "no such publication" } });
    expect(await loadContest(fakeContestId)).toEqual({ kind: "notFound" });
    answer(403, { error: { code: "contest_not_visible", message: "pending" } });
    expect(await loadContest(fakeContestId)).toEqual({ kind: "notVisible" });
  });

  it("reports any other failure with the server's message", async () => {
    answer(500, { error: { code: "boom", message: "database away" } });
    expect(await loadContest(fakeContestId)).toEqual({ kind: "failed", message: "database away" });
  });
});
