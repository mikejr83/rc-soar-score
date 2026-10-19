# ADR 0004: Localization approach for the contest administration app

- Status: proposed
- Date: 2026-10-19
- Decision issue: #324

## Context

The contest app has no localization today: about 220 hard-coded `Text('...')` strings, ISO-style timestamps from `ContestTime.format`, and `intl` present only as a dependency. Epic #318 adds a per-account preferred locale (#323) and uses it in the admin UI (#325). Mike's decision of 2026-10-08: en-US plus a couple of other locales, chosen to show how values change. Pilot-facing times always use the contest's zone, never the viewer's preference.

## Decision

- **Mechanism:** Flutter's built-in localization: `flutter_localizations`, `intl`, ARB files under `apps/soar_score_contest/lib/l10n/` and `flutter gen-l10n` (`l10n.yaml`, synthetic package off, generated output committed only if the repo already commits generated code). It works the same on web and native, needs no extra runtime dependency, and gives typed message getters with plural and placeholder support.
- **What the locale controls:**
  - UI strings in the contest app.
  - Date and time layout, and decimal and grouping separators for numbers shown to the director.
  - Scores, penalties, heights and times in the scoring UI use the locale's decimal separator on display. Stored and API values stay locale-free (UTC ISO timestamps, `.` decimals), and rounding rules come from the discipline, never from the locale.
- **What the locale does not control:** the time zone (separate preference), pilot-facing times (contest zone), and anything in published results or reports until the public site and report briefs decide their own handling.
- **Initial locales:** `en-US` (default and source), `en-GB` (same language, different date order and 24-hour clock), `de-DE` (translated strings, decimal comma, different date layout). `de-DE` ships with a small reviewed set of strings; untranslated keys fall back to `en-US`.
- **`soar_score_core` formatting:** core stays Flutter-free. `ContestTime` gains an optional `locale` argument backed by `intl` date formatting; with no locale it keeps today's output, so pilot-facing callers do not change. Zone data keeps coming from the `timezone` package.
- **Unset preference:** use the device locale if it is one of the supported locales, otherwise `en-US`.
- **#29:** already closed as a duplicate. Its locale formatting item is covered here; its accessibility items are tracked elsewhere.

## Rejected options

- **`slang`, `easy_localization` or other packages:** extra dependencies and generated formats for no gain over `gen-l10n` at this size.
- **Hand-written string maps:** no plural or placeholder support, and no tooling to find missing keys.
- **Server-rendered strings:** the offline app must work with no server.
- **Locale-aware storage or API values:** would break sync and cross-device consistency; formatting is display only.

## Consequences

- Follow-up implementation issue: enable `gen-l10n`, add the `en-US`, `en-GB` and `de-DE` ARB files, wire `MaterialApp.router` locale from the account preference, migrate strings feature by feature (starting with Settings, the shell and the contest list), and add a locale argument to `ContestTime`.
- New user-facing strings in contest app PRs go through ARB files once the follow-up lands.
- #323 validates the preferred locale against this list; #325 builds the picker from it.
