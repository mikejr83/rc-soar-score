# Releasing

How a release is cut, so someone other than the author can do it. What a
release deploys, the secrets and the hosts are in [Deploying](deploying.md);
this page is the checklist around it.

## Versions and tags

- One version for everything (API, web apps, public site, Windows app). The
  Git **tag is the only source of truth**: `vMAJOR.MINOR.PATCH`, with an
  optional pre-release suffix `-alpha.N`, `-beta.N` or `-rc.N` (for example
  `v0.1.0-alpha.6`, `v0.2.0`). The Deploy workflow refuses any other tag before
  it changes anything. The `version:` fields in the pubspecs and
  `package.json` stay at `0.1.0` and are not bumped; the Windows build takes its
  version from the tag.
- Before 1.0: alpha releases count up (`-alpha.N`); a new `MINOR` marks a
  milestone such as the first public beta. From 1.0: `MAJOR` for a breaking
  change of the API or of a stored/exported file format, `MINOR` for new
  features, `PATCH` for fixes only.
- Every published release deploys, pre-releases included, because the server
  and the clients ship together. Tick **Pre-release** for alpha, beta and rc.
- **Database schema.** Until the first release that is not an alpha, schema
  changes are made in place in version 1 and the server migrates on start;
  testers' data may need a reset, and the release notes must say so. From
  then on every schema change is a numbered migration, and sync's supported
  schema range (`min_schema_version` / `max_schema_version`) decides whether
  an older app can still sync. A release that changes the schema is at least a
  `MINOR`.

## Cutting a release

1. **Check master.** CI is green on the latest commit. Look at the merged PRs
   since the last release for schema changes, new secrets or settings, and
   anything that needs a reset. Do the manual steps they need first (for
   example a new secret in the `Production` environment).
2. **Do not rotate `INVITATION_SECRET`.** Changing it invalidates every
   printed QR code and guest session.
3. **Create the release** in GitHub: Releases > Draft a new release, new tag
   (`vX.Y.Z[-alpha.N]`) on `master`, Pre-release ticked if it is one. Write a
   short intro if you want one (leave the body otherwise empty) and **Publish**.
4. **Publishing starts three workflows**, nothing else is manual:
   - **Deploy** checks the tag, deploys the API to Fly (and smoke-tests it),
     then the public site and both web apps ([Deploying](deploying.md)).
   - **Release Windows alpha** builds the Windows zip and attaches it to the
     release a few minutes later.
   - **Release notes** writes the release notes (below).
5. **Watch Actions** until all three are green, and wait for the zip to appear
   on the release before announcing it.
6. **Check after the deploy** (from your own machine; the cloud environment
   cannot reach the API):
   - `fly logs -a rc-soar-score-api` shows `Database open and migrated.`
   - `scripts/hosted-smoke.sh` passes (the Deploy workflow already ran it).
   - `https://score.rcsoarscore.com/invitations/x` shows the invalid-link page.
   - Install the zip and confirm sign-in and a sync reach `api.rcsoarscore.com`.
7. Read the release notes, edit anything wrong in the GitHub UI, then announce.

## Release notes

The **Release notes** workflow (`.github/workflows/release-notes.yml`,
`scripts/generate_release_notes.py`) runs when a release is published. It
lists the pull requests merged since the previous release (GitHub's generated
notes, grouped by [`.github/release.yml`](../.github/release.yml)), sends their
titles, labels and descriptions to Claude, and writes a tester-friendly summary
into the release body: what's new, new features, fixes, and a "Before you
update" section.

- The text is placed between `<!-- release-notes:start -->` and
  `<!-- release-notes:end -->`. Anything you wrote above the marker is kept.
  Edit the result freely in the GitHub UI afterwards; do not remove the markers
  if you want a re-run to replace only the generated part.
- It needs the `ANTHROPIC_API_KEY` secret in the `Production` environment
  (Settings > Environments > Production). Set `RELEASE_NOTES_MODEL` in the
  workflow to change the model.
- If the model call fails, GitHub's plain generated notes are used, so the
  release is never empty. The workflow is separate from Deploy, so a failure
  here never blocks a deploy.
- Good PR titles and descriptions make good notes. The model is told not to
  invent features, but read the result before announcing.
- **Preview or re-run:** Actions > Release notes > Run workflow with an
  existing tag. A manual run only prints the notes in the job log; to replace
  the notes on the release, edit them by hand or run
  `scripts/generate_release_notes.py <tag>` locally with `GH_TOKEN` and
  `ANTHROPIC_API_KEY` set.

## Rollback

1. Actions > Deploy > Run workflow, enter the **earlier tag**, choose the
   targets. What runs is what that tag held. (The Windows zip of the bad
   release stays attached; mark the release as superseded in its notes.)
2. **Database.** Rolling back does not undo schema changes. If the bad release
   changed the schema, also restore Neon to a point before the deploy
   (point-in-time restore); see [deploy-api-fly.md](deploy-api-fly.md#rollback).
   Check the release's schema changes first.
3. Record what happened in the issue that tracks the problem.

## Hotfix

For a fix that cannot wait for what is on `master`:

1. Branch `hotfix/vX.Y.Z` from the **release tag** that is live.
2. Make only the fix, with a test, and open a PR into the hotfix branch.
   CI runs on it like on any PR.
3. When the checks pass and the PR is merged, publish a release with the next patch tag
   (`vX.Y.(Z+1)`), **target the hotfix branch**. Deploy runs from that tag.
4. Merge the same fix into `master` (cherry-pick or merge the branch) so the
   next release has it. Delete the hotfix branch afterwards.

For alpha releases there is no hotfix branch: fix on `master` and publish the
next `-alpha.N`.

## Windows distribution

The Windows app ships as a zip attached to the release. Installer and signing
choices are in #221 and a Microsoft Store listing in #225; neither is part of
this process yet. When one is added, its build joins the Windows workflow and
its upload step goes into the checklist above.
