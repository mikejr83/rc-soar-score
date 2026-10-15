# tools/gs_importer

Windows-native helper that reads GliderScore `.mdb` databases (Jet 3/4 Access
files). Ships the prebuilt `mdb-json.exe` and `mdb-tables.exe` binaries from
the [lsgunth/mdbtools-win] fork together with their runtime DLLs. CMake
installs them under `gs_importer/` next to the app executable; the Flutter
app invokes them as child processes and parses their JSON output.

## Files

| File                          | Purpose                                          |
| ----------------------------- | ------------------------------------------------ |
| `bin/x86/mdb-json.exe`        | Export one table as JSON objects (one per line)  |
| `bin/x86/mdb-tables.exe`      | Print the user table names, space-separated      |
| `bin/x86/libmdb-3.dll`        | Runtime library for both exes                    |
| `bin/x86/libgcc_s_dw2-1.dll`  | GCC runtime for libmdb-3.dll                     |
| `bin/x86/libiconv-2.dll`      | Character-set conversion used by libmdb-3.dll    |
| `bin/x86/libwinpthread-1.dll` | Win32 pthreads used by libmdb-3.dll              |
| `COPYING`                     | GPLv2 license text (the `mdb-*` exes)            |
| `COPYING.LIB`                 | LGPL v2 license text (libmdb, upstream mdbtools) |
| `LGPL-2.1.txt`                | LGPL 2.1 text (libiconv, win_pthreads)           |
| `NOTICE.txt`                  | Provenance, SHA-256 checksums, GPL source offer  |

Installation: `apps/soar_score_contest/windows/CMakeLists.txt` validates the
six files in `bin/x86/` plus the four files above and installs them into
`gs_importer/` next to the app executable, so the build output — and the
installer that ships it — carries the license texts with the binaries.

## Invocation

The app finds the helper relative to its own directory:
`gs_importer/mdb-json.exe` and `gs_importer/mdb-tables.exe` (both 32-bit,
run under WoW64 on x64 Windows).

Table list:

```
mdb-tables.exe <path.mdb>
```

stdout: user table names separated by spaces, one line. Exit code 0 on
success.

Table export:

```
mdb-json.exe [-T <strftime datetime fmt>] [-D <strftime date fmt>] <path.mdb> <table>
```

stdout: one JSON object per row, one per line — e.g.
`{"CompNo":1,"CompDate":"2009-03-06T00:00:00","CompName":"..."}`.

- Dates: Jet OLE double → local date/time via `strftime`. Use
  `-T "%Y-%m-%dT%H:%M:%S"` for naive ISO 8601 (this is what Soar Score
  passes).
- Nulls: fields are omitted from the row object, not emitted.
- Numbers: emitted as JSON numbers (int/float as stored).
- Text: UTF-8, JSON-escaped; control bytes become `\u00XX`.
- Binary / OLE / GUID: emitted as
  `{"$binary": "<base64>", "$type": "00"}`.

Progress and errors go to stderr; use exit code and stderr to detect
failures. The DB file must not change between calls.

## Why prebuilt binaries

The native Windows app is the only import surface, low-tech users need no
extra tooling, and a separate GPLv2 process keeps Soar Score source free of
GPL code (no linking, no source changes to upstream). The binaries are
pinned to an exact upstream commit (see NOTICE.txt); if a future GliderScore
file format breaks them, rebuild from [mdbtools/mdbtools] with MinGW32
following the upstream README, and replace the files at the same
bin/x86/ paths.

[lsgunth/mdbtools-win]: https://github.com/lsgunth/mdbtools-win
[mdbtools/mdbtools]: https://github.com/mdbtools/mdbtools
