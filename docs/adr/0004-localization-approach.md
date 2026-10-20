# ADR 0004: Localization approach for the contest administration app

- Status: accepted
- Date: 2026-10-19
- Decision issue: #324

## Context

The contest app has no localization today: about 220 hard-coded `Text('...')` strings, ISO-style timestamps from `ContestTime.format`, and `intl` present only as a dependency. Epic #318 adds a per-account preferred locale (#323) and uses it in the admin UI (#325). Mike's decisions: en-US plus other locales (2026-10-08), the full target list and volunteer translators (2026-10-19). Pilot-facing times always use the contest's zone, never the viewer's preference.

## Decision

- **Mechanism:** Flutter's built-in localization: `flutter_localizations`, `intl`, ARB files under `apps/soar_score_contest/lib/l10n/` and `flutter gen-l10n` (`l10n.yaml`, synthetic package off, generated output committed only if the repo already commits generated code). It works the same on web and native, needs no extra runtime dependency, and gives typed message getters with plural and placeholder support.
- **What the locale controls:**
  - UI strings in the contest app.
  - Date and time layout, and decimal and grouping separators for numbers shown to the director.
  - Scores, penalties, heights and times in the scoring UI use the locale's decimal separator on display. Stored and API values stay locale-free (UTC ISO timestamps, `.` decimals), and rounding rules come from the discipline, never from the locale.
- **What the locale does not control:** the time zone (separate preference), pilot-facing times (contest zone), and anything in published results or reports until the public site and report briefs decide their own handling.
- **Locales:** `en-US` is the source language and the only locale in Alpha. Its files use Flutter's base-language name: `app_en.arb` with `@@locale: "en"` and `Locale('en')`. The text is the en-US text, and the preference tag `en-US` resolves to that bundle. A separate `app_en_US.arb` is added only if an English variant (such as `en-GB`) needs to differ. The target list (Mike, 2026-10-19) is: Chinese (`zh-CN`, Simplified; Traditional is a later question), Czech (`cs`), Danish (`da`), English (`en-US`), Spanish (`es-ES`), Finnish (`fi`), French (`fr-FR`), German (`de`), Greek (`el`), Hungarian (`hu`), Italian (`it`), Japanese (`ja`), Norwegian (`nb`, Bokmål), Polish (`pl`), Slovak (`sk`), Slovenian (`sl`), Swedish (`sv`), Turkish (`tr`) and Ukrainian (`uk`). A locale is offered in the picker only once its translation is complete enough to ship; untranslated keys fall back to `en-US`. None of the targets is right-to-left. Region variants such as `en-GB` are added only on request.
- **Community translation:** translators work on one ARB file per locale, which is plain JSON and needs no Flutter toolchain.
  1. The repo keeps `app_en.arb` as the source, with a `@key` description for each string so translators see the context.
  2. A script (`apps/soar_score_contest/tool/l10n.dart`) writes a ready-to-translate template for a locale (the English text, the descriptions, and any translations already there).
  3. The translator edits it in any text editor and sends the file back, either as a pull request or as an attachment to an issue labelled `area:l10n`.
  4. The same script validates the returned file (valid JSON, same keys, placeholders and plural forms intact, no stray keys) and reports what is missing. A maintainer then adds it under `lib/l10n/`.
  5. Translators can preview their file without building the app: a native-build setting loads an ARB file from disk as a temporary override for the chosen locale. This is a follow-up, not a prerequisite.
     A hosted translation platform with a free open-source plan (Weblate or Crowdin) can be added later on the same ARB files if volunteers prefer a web editor; nothing in this ADR depends on it.
- **`soar_score_core` formatting:** core stays Flutter-free. `ContestTime` gains an optional `locale` argument backed by `intl` date formatting; with no locale it keeps today's output, so pilot-facing callers do not change. Zone data keeps coming from the `timezone` package.
- **Unset preference:** use the device locale if it is one of the supported locales, otherwise `en-US`.
- **#29:** already closed as a duplicate. Its locale formatting item is covered here; its accessibility items are tracked elsewhere.

## Rejected options

- **`slang`, `easy_localization` or other packages:** extra dependencies and generated formats for no gain over `gen-l10n` at this size.
- **Hand-written string maps:** no plural or placeholder support, and no tooling to find missing keys.
- **Server-rendered strings:** the offline app must work with no server.
- **Locale-aware storage or API values:** would break sync and cross-device consistency; formatting is display only.

## Consequences

- Follow-up implementation issue: enable `gen-l10n`, add `app_en.arb` with descriptions, the `tool/l10n.dart` template and validation script, and a contributor guide for translators, wire `MaterialApp.router` locale from the account preference, migrate strings feature by feature (starting with Settings, the shell and the contest list), and add a locale argument to `ContestTime`.
- New user-facing strings in contest app PRs go through ARB files once the follow-up lands.
- #323 validates the preferred locale against the list of shipped locales (en-US in Alpha); #325 builds the picker from it.
