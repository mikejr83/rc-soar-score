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

Every time the app opens it shows an alpha warning (contest data may need to be
reset in a later release, check the scoring by hand, self-scoring and results
sharing are not finished). Tick the acknowledgement and choose **Continue** to
use the app.

Then choose **Continue offline** on the first screen. Sign-in is not part of the
alpha zip.

## Where your data lives

Contests are kept in the application support folder of your Windows user
profile, not next to the program. Deleting the unzipped folder never deletes a
contest. To back up, copy that folder while the app is closed.

## Update

Close the app, download the newer zip, unzip it, and replace the old folder.
Your contests are kept. The version shows at the bottom of the settings menu
(the gear at the bottom of the left rail) and on a contest's Sync page.

## Open source licences

The app is free software under the AGPL-3.0; the source is at
https://github.com/mikejr83/rc-soar-score. The zip holds
`THIRD_PARTY_NOTICES.txt`, which lists the open source libraries in the app
and their licences. In the app, Settings > About > Licences on this device
shows them with no network. Online they are at
https://rcsoarscore.com/open-source#contest-app

## Clean-machine checklist

Run this on a Windows machine that has never had the app:

- [ ] Unzip, run the exe, get past SmartScreen
- [ ] The alpha warning shows; Continue stays off until the box is ticked
- [ ] Continue offline, create a contest, close the app
- [ ] Unzip a newer build over the old folder, reopen: the contest is still there
- [ ] The version in the menu matches the release

## For maintainers

Create and publish a GitHub release for a new tag such as `v0.1.0-alpha.1`
(tick "Pre-release" for alphas; "Generate release notes" fills the notes). The
workflow `.github/workflows/release-windows.yml` starts when the release is
published, builds the zip, and attaches it to that release a few minutes later.
Publishing also deploys the hosted apps (docs/deploying.md). The build name is the
tag without its pre-release suffix (`0.1.0`, because the Windows file version is
numeric) and the build number is the workflow run number. The workflow also
runs `dart scripts/generate_licences.dart --product contest-app --notices
THIRD_PARTY_NOTICES.txt` and puts the file in the zip. Run the workflow by
hand to build without releasing; the result is a workflow artifact holding the unzipped folder. Actions has no
credits at the moment, so check that the build works on a Windows machine
first.
