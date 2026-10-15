# Windows Installer Requirements

What an installer for the offline contest app (`soar_score_contest` on Windows)
must do. The packaging format, signing and update path are still open in #221
(an unsigned Inno Setup installer was the leaning, and #225 investigates the
Microsoft Store). This page records the requirements that hold for any format,
so the installer ticket starts from a list and not from a debugging session.

Sign-in is the reason this page exists: Auth0 returns to the app through a
custom URL scheme, and Windows only delivers that callback if the scheme is
registered. See [Auth0 Setup](auth0-setup.md) and
[Environment Setup](environment-setup.md#contest-app-sign-in).

## Must do

### 1. Install the whole build output

Install everything in `build\windows\x64\runner\Release\`, not just the
`.exe`: `data\`, `flutter_windows.dll`, the plugin DLLs, and the OpenSSL DLLs
(`libssl-3-x64.dll`, `libcrypto-3-x64.dll`) that `auth0_flutter` bundles next
to the executable. Without the OpenSSL DLLs, sign-in fails at runtime even
though the app starts.

The GliderScore import helpers ship as a `gs_importer\` folder in that same
output, next to the executable: `mdb-json.exe`, `mdb-tables.exe`, the
MinGW runtime DLLs they load (`libmdb-3.dll`, `libgcc_s_dw2-1.dll`,
`libiconv-2.dll`, `libwinpthread-1.dll`), and the GPL/LGPL license texts
(`COPYING`, `COPYING.LIB`, `LGPL-2.1.txt`) with `NOTICE.txt` (the source
offer is in `NOTICE.txt`). The app finds `gs_importer\mdb-json.exe` relative
to its own directory, and answers 503 `import_unavailable` (not 404) if the
folder or an executable is missing, so the import wizard stays visible even
where the helpers were not installed. CMake installs those ten files, so a
build from source already lays them down; the installer must carry the
folder through (see [tools/gs_importer](../tools/gs_importer)/README.md).

### 2. Register the `com.soarscore.contest` URL scheme

Register it for the installing user under `HKEY_CURRENT_USER` (no
administrator rights needed), pointing at the installed executable.

The app also registers it itself, just before every sign-in
(`lib/auth/url_scheme_registrar.dart`), and rewrites the keys when they point
at a different executable. So sign-in works even if the installer did not
register the scheme, and a development build can take it over. The installer
should still register it: that keeps the registration correct before the first
sign-in (for example when the callback launches the app) and lets the uninstall
remove it cleanly. Both write the same keys, so they do not conflict.

```reg
[HKEY_CURRENT_USER\Software\Classes\com.soarscore.contest]
@="URL:RC Soar Score"
"URL Protocol"=""

[HKEY_CURRENT_USER\Software\Classes\com.soarscore.contest\shell\open\command]
@="\"<install dir>\\soar_score_contest.exe\" \"%1\""
```

Rules:

- The scheme and the `"%1"` argument are both required. The runner reads the
  callback URL from `argv[1]` (`windows/runner/main.cpp`).
- The scheme is fixed in code and must match `Auth0Config.defaultWindowsScheme`
  (`lib/auth/auth_config.dart`) and the Auth0 application's callback and
  logout URL `com.soarscore.contest://callback`. Change all of them together.
- Use the real install path. A per-user install that moves between versions
  must rewrite the key on every install and upgrade, not only the first.
- An all-users (administrator) install may register under
  `HKEY_LOCAL_MACHINE\Software\Classes` instead. Do not do both, or a stale
  per-user key can shadow the machine one.

Inno Setup sketch:

```ini
[Registry]
Root: HKCU; Subkey: "Software\Classes\com.soarscore.contest"; ValueType: string; ValueData: "URL:RC Soar Score"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\com.soarscore.contest"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""
Root: HKCU; Subkey: "Software\Classes\com.soarscore.contest\shell\open\command"; ValueType: string; ValueData: """{app}\soar_score_contest.exe"" ""%1"""
```

An MSIX package declares the same thing in its manifest instead of the
registry (`uap:Protocol Name="com.soarscore.contest"`) and registers it at
install time.

### 3. Remove the registration on uninstall

Delete `HKCU\Software\Classes\com.soarscore.contest` (Inno's `uninsdeletekey`
does this). A leftover key points the browser callback at a missing file.

### 4. Install the Visual C++ runtime

The Flutter Windows runner and the OpenSSL DLLs need the Visual C++
Redistributable (x64). Install it, or check for it and prompt, so a clean
machine does not fail with a missing `VCRUNTIME140.dll`.

## Must not do

- Do not put an Auth0 client secret, token or tenant credential in the
  installer. The client IDs and the audience are public identifiers compiled
  into the app, and there is no client secret.
- Do not delete user data on uninstall without asking. The local database
  (`soar_score.db`) lives in `%APPDATA%` (the per-user application support
  folder), and the stored sign-in session is in the per-user secure store.
  Offer "remove my data" as an explicit, unticked choice.
- Do not run a second copy per launch. The runner already enforces a single
  instance and forwards a callback to the running window, so the installer's
  shortcut and the URL handler can both start the same `.exe`.

## Should do

- Create the Start menu entry (and an optional desktop shortcut) for the
  executable, with no arguments.
- Let the installer upgrade in place: the same registry rewrite, no second
  install. Keep the previous database; the app owns schema migrations.
- Offer to launch the app after install.
- Record the version in the installer so a repair or a forced update from the
  sync protocol (#221 question 3) can replace the files.

## Open items that change this page

- **Package format and signing (#221):** an unsigned installer shows a
  SmartScreen warning that the download page should explain. MSIX replaces
  sections 2 and 3 with manifest declarations and has its own install rules.
- **Microsoft Store (#225):** a Store build registers the scheme through the
  manifest, and the Auth0 callback may need review for a packaged app.
- **Token renewal (#388):** unrelated to the installer, but until it lands a
  Windows session ends when the access token expires.

## Checking an installer

On a clean Windows user profile:

1. Install, then run `reg query HKCU\Software\Classes\com.soarscore.contest\shell\open\command`.
   The value must be the installed `.exe` and `"%1"`.
2. Start the app, choose Sign in, and finish Universal Login. The browser must
   hand back to the running app, which then shows "Signed in as ...".
3. With the app closed, open `com.soarscore.contest://callback` from the Run
   dialog. The app should start and not open a second window when it is already
   running.
4. Uninstall, then repeat the `reg query`. The key must be gone.
