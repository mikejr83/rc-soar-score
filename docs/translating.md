# Translating Soar Score

The contest app is translated by volunteers. You need a text editor, and nothing else is required to start: no Flutter, no build. This follows [ADR 0004](adr/0004-localization-approach.md).

## What gets translated

Every message in the app lives in one file per language, `apps/soar_score_contest/lib/l10n/app_<locale>.arb`. English (`app_en.arb`) is the source. An ARB file is plain JSON: each message has a key, its text, and a short `description` that says where it appears.

Alpha ships English only. A language is added to the app once enough of it is translated.

## Target languages

Chinese (Simplified, `zh_CN`), Czech (`cs`), Danish (`da`), English (`en_US`), Spanish (`es_ES`), Finnish (`fi`), French (`fr_FR`), German (`de`), Greek (`el`), Hungarian (`hu`), Italian (`it`), Japanese (`ja`), Norwegian Bokmål (`nb`), Polish (`pl`), Slovak (`sk`), Slovenian (`sl`), Swedish (`sv`), Turkish (`tr`) and Ukrainian (`uk`).

## How to translate

1. Ask for the template for your language by opening an issue labelled `area:l10n`, or, if you have Dart installed, make it yourself from `apps/soar_score_contest`:

   ```
   dart run tool/l10n.dart template fr-FR --out app_fr_FR.arb
   ```

   The template lists every message with the English text filled in. If a translation already exists, it keeps it so you can finish or improve it.

2. Open the file in a text editor and replace each English text with your translation. Leave the keys and the `@` lines alone.
   - Keep placeholders such as `{name}` exactly as written; move them where your language needs them.
   - Keep plural forms such as `{count, plural, one{...} other{...}}`, and add the extra forms your language uses.
   - A message you cannot translate yet can stay in English; the app shows English for it.
   - Pilots and directors read these texts during a contest, so prefer short, plain wording over word-for-word translation.

3. Check your file, if you have Dart:

   ```
   dart run tool/l10n.dart validate app_fr_FR.arb
   ```

   Errors (a changed placeholder, broken or malformed braces, a plural or select that lost an option, an empty message, a message that does not exist, a language that does not match the file name `app_<locale>.arb`) must be fixed. To leave a message untranslated, remove its key or keep the English text; do not empty it. Warnings are only reminders of what is untranslated.

4. Send the file back: attach it to the issue, or open a pull request that adds it under `apps/soar_score_contest/lib/l10n/`. A maintainer checks it with the same script and adds it to the app.

## For maintainers

- Adding a language: put the checked `app_<locale>.arb` in `lib/l10n/`, run `flutter gen-l10n` in `apps/soar_score_contest`, commit the generated files, add the locale to `SupportedLocales.ids` in `soar_score_core`, and, for date layouts, call `initializeDateFormatting` at start-up.
- New app text goes in `app_en.arb` with a `description`; never hard-code a new string in a widget that has been migrated.
