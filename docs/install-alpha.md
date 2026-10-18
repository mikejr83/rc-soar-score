# Install the Windows Alpha

The F5J alpha of the contest app runs offline on Windows. It is a zip, not an
installer, and it is not signed yet.

## Install

1. Download `soar-score-contest-windows-<version>.zip` from the
   [GitHub Releases](https://github.com/mikejr83/rc-soar-score/releases) page.
2. Unzip it anywhere you like, but not into Program Files.
3. Run `soar_score_contest.exe`.
4. Windows SmartScreen may say "Windows protected your PC" because the app is
   not signed. Click **More info**, then **Run anyway**.

Choose **Continue offline** on the first screen. Sign-in is not part of the
alpha zip.

## Where your data lives

Contests are kept in the application support folder of your Windows user
profile, not next to the program. Deleting the unzipped folder never deletes a
contest. To back up, copy that folder while the app is closed.

## Update

Close the app, download the newer zip, unzip it, and replace the old folder.
Your contests are kept. The version shows at the bottom of the settings menu
(the gear at the bottom of the left rail) and on a contest's Sync page.

## Clean-machine checklist

Run this on a Windows machine that has never had the app:

- [ ] Unzip, run the exe, get past SmartScreen
- [ ] Continue offline, create a contest, close the app
- [ ] Unzip a newer build over the old folder, reopen: the contest is still there
- [ ] The version in the menu matches the release

## For maintainers

Push a tag such as `v0.1.0-alpha.1`. The workflow
`.github/workflows/release-windows.yml` builds the zip and attaches it to a
**draft** release; review the notes and publish it. The build name is the
tag without its pre-release suffix (`0.1.0`, because the Windows file version is
numeric) and the build number is the workflow run number. Run the workflow by
hand to build a zip as a workflow artifact without releasing. Actions has no
credits at the moment, so check that the build works on a Windows machine
first.
