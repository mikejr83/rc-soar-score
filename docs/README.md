# Documentation

Guides and reference pages for developing, releasing and using Soar Score. Product requirements and rules live in [`plan/`](../plan), not here. Agent and contributor conventions are in [AGENTS.md](../AGENTS.md).

These documents are licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/); see the [project README](../README.md#license) for how to credit them.

## Decisions

- [Architecture decision records](adr/README.md): why the project made its major technical choices, with an index and how to add one.

## Development setup

- [Environment Setup](environment-setup.md): tools and steps to build, run and test on a development machine.
- [Auth0 Setup](auth0-setup.md): what to configure on the Auth0 side so the apps and server can sign people in.
- [Translating Soar Score](translating.md): how volunteers translate the contest app (follows [ADR 0004](adr/0004-localization-approach.md)).
- [Open Source Licences and Notices](open-source-licences.md): how the project meets the obligations of the open source software it ships.

## Deploying and releasing

- [Releasing](releasing.md): the checklist for cutting a release.
- [Deploying](deploying.md): what a published release deploys, the hosts and the secrets.
- [Deploy the API server to Fly.io](deploy-api-fly.md): hosting the API on Fly.io with PostgreSQL on Neon.
- [Windows Installer Requirements](windows-installer-requirements.md): what any installer for the offline Windows contest app must do.
- [alpha-readme.txt](alpha-readme.txt): the plain-text readme template (with a `{{VERSION}}` placeholder) shipped inside the Windows alpha zip.

## Design and behaviour

- [Contest options audit](contest-options-audit.md): audit of the core contest options (issue #154).
- [Embedded API security](embedded-api-security.md): threat model and decision for the API the Windows app serves in process (#425).
- [When the apps talk to the service](sync-schedule.md): how often the apps contact the service, and the web refresh behaviour.

## User guides

- [Install the Windows Alpha](install-alpha.md): downloading and running the offline F5J alpha of the contest app.
- [Import pilots from GliderScore](import-pilots-from-gliderscore.md): adding pilots from a GliderScore database to your participants list.
- [Import competitions from GliderScore](import-competitions-from-gliderscore.md): turning GliderScore competitions into contests, with their draw and scores.
