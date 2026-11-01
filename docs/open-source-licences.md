# Open Source Licences and Notices

How the project meets the obligations of the open source software it ships
(#687). Visitors see the result at `/open-source` on the public site; the
contest app (#688) and the self-scoring app (#689) link to its `#contest-app`
and `#self-scoring` sections.

Our own licences: code AGPL-3.0, documentation CC BY 4.0 (decision #218).

## Generated data

`scripts/generate_licences.dart` (wrappers `scripts/generate-licences.sh` and
`.ps1`) reads the lockfiles and writes
`apps/soar_score_web/src/content/licences.json`:

- **Dart and Flutter**: the dependency graph from `dart pub deps --json` for
  each shipped app (production dependencies only, transitive included),
  versions from `pubspec.lock`, licence texts from the pub cache.
- **npm**: the production entries of `apps/soar_score_web/package-lock.json`,
  texts from `node_modules`. Only packages that apply to Vercel (Linux x64,
  glibc) are listed; the musl and WebAssembly variants are not shipped.
- **Bundled components** are listed in the generator itself: the three OFL
  fonts, the Flutter framework and engine and the Dart runtime
  (`scripts/licence-texts/`), the GliderScore import helpers in
  `tools/gs_importer/`, and the OpenSSL DLLs that `auth0_flutter` bundles.

The generator fails when it cannot identify a licence. Fix it in
`scripts/licence-overrides.json` (licence id, text files under
`scripts/licence-texts/`, or `textFrom` another package) rather than by hand
in the output.

Run it after `dart pub get` (or `melos bootstrap`) and `npm ci` in
`apps/soar_score_web`. Plain-text notices for one product, for the Windows
zip, come from the same data:

```
scripts/generate-licences.sh --product contest-app --notices THIRD_PARTY_NOTICES.txt
```

The staleness check is a vitest test (`src/lib/licences.test.ts`, run by
`npm test` and the `public-site` CI job). It fails when `pubspec.lock`,
`package-lock.json` or the overrides changed since the data was generated.
`scripts/generate-licences.sh --check` does the full comparison locally.

## Copyleft review

| Component                                             | Licence                            | Where                            | What it requires                                                                          | Status                                                                                    |
| ----------------------------------------------------- | ---------------------------------- | -------------------------------- | ----------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| RC Soar Score                                         | AGPL-3.0                           | all products                     | Offer the source to network users                                                         | Public repository; the page links the build's commit; apps link to the page (#688, #689). |
| mdbtools utilities (`mdb-json.exe`, `mdb-tables.exe`) | GPL-2.0                            | Windows build only               | Licence text and a source offer; run as separate programs, so the app is not a derivative | `COPYING` and the source offer in `NOTICE.txt` ship in `gs_importer/`.                    |
| `libmdb-3.dll`                                        | LGPL-2.0                           | Windows build only               | Licence text, source offer, the DLL stays replaceable (separate file)                     | Shipped as a DLL beside the helpers.                                                      |
| `libiconv-2.dll`                                      | LGPL-2.1                           | Windows build only               | Same as above                                                                             | Same.                                                                                     |
| `libgcc_s_dw2-1.dll`                                  | GPL-3.0 with GCC runtime exception | Windows build only               | GPL-3.0 text and the exception text with the DLL                                          | **Action**: `tools/gs_importer` has no GPL-3.0 or exception text yet.                     |
| `libwinpthread-1.dll`                                 | MIT/BSD-style (winpthreads)        | Windows build only               | Copyright notice with binaries                                                            | **Action**: add the winpthreads `COPYING` text; `NOTICE.txt` only names it.               |
| OpenSSL DLLs                                          | Apache-2.0                         | Windows build only               | Licence text and notices with the binary                                                  | Covered by `THIRD_PARTY_NOTICES.txt`.                                                     |
| `dbus`, `nm` (Dart)                                   | MPL-2.0                            | Flutter apps (Linux plugin path) | File-level source availability for modified files                                         | Unmodified; the page links their sources.                                                 |
| `@img/sharp-libvips-linux-x64`                        | LGPL-3.0                           | Public site build on Vercel      | Binary is not distributed to users; notice and text listed                                | Listed with LGPL-3.0 and GPL-3.0 texts.                                                   |

Before the Windows alpha is distributed:

1. Add the winpthreads copyright text and the GPL-3.0 plus GCC runtime
   exception texts to `tools/gs_importer/` and install them with the helpers
   (`docs/windows-installer-requirements.md`).
2. Put `THIRD_PARTY_NOTICES.txt` (generated as above) in the zip.
3. Flutter's engine bundles further components (Skia, HarfBuzz, ICU, FreeType
   and others). The generated file credits Flutter and points to its
   repository. An in-app licence screen (Flutter's `showLicensePage`) would
   cover them completely and is worth considering with #688 and #689.
