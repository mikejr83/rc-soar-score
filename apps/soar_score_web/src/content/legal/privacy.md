# Privacy Policy (DRAFT for review, not legal advice)

**Effective date:** [to be set at launch]
**Operator:** Laminar Stack, Mike Gardner ("we", "us"). Contact: [privacy contact email, TBD]

RC Soar Score helps radio controlled sailplane contest directors and pilots set up, run, score and publish contests. This policy covers the public website (rcsoarscore.com), the contest administration app (web and Windows), the participant scoring app, and our servers. The software is open source (AGPL-3.0); this policy covers the hosted service we run, not copies run by others.

## 1. The short version

- Published contest results are public. They show contest details, pilot names (or a name chosen by the pilot), scores and placings. They never show email addresses.
- Email addresses are private. We use them for sign-in, invitations, and publication verification, and never publish them.
- You can use the Windows app offline with no account. Then we receive nothing.
- We do not sell personal data and do not run advertising.
- You can ask us to remove your details from published results.

## 2. Who is who

Contest directors enter the pilots' details for their own contests. For that private contest data the director decides what is collected and why, and we host it for them. For the public results, the sign-in system and this website, we decide. A director's data is not deleted because a third party asks; ask the director first.

Imported data: if a director imports a contest from other scoring software, any pilot details in that file (including emails) are copied in; the import tells them so.

## 3. What we collect

| Who | Data | Why |
|---|---|---|
| Account holders | Name, email address (and whether our sign-in provider verified it), a stable account id, optional preferred time zone and language | Sign in, own contests, receive invitations |
| Contest directors | Contests, participant (pilot and helper) records including name and optionally email and AMA/club details they choose to enter, rounds, matrix, scores, notes, audit history | Run and score contests |
| Pilots invited to self-score | An invitation link (a random credential, stored only in protected form), a temporary guest identity, the scores they enter | Let pilots enter their own scores without an account |
| Pilots with an account | Optional directory listing (you choose whether you are listed and whether directors can see your email), optional public name | Let directors find you; control how you appear in results |
| Anonymous publishers | An email address, verified with a one-time code (valid 10 minutes), kept private | Prove control of the email, manage and later claim the publication |
| People using the support form | Name, email, role, request type, message | Answer your request |
| All visitors | Technical data: IP address, browser type, requested pages, timestamps, error details; page-view statistics [analytics provider TBD, see section 10] | Security, abuse prevention, reliability, understanding site use |
| Signed-in users' devices | Installation record: a label (by default derived from the computer's name, [change to a generic label before launch]), platform, last-seen and last-sync times | Show and revoke your connected devices |
| Everyone whose data syncs | A change log of synced records (including the pilot name and email fields they contain), who made the change, which device, and when | Sync, conflict handling, debugging and audit |

We do not collect payment data, precise location, or data from children knowingly. [You must be at least 16 to register an account. Junior pilots may appear in results entered by a director, who is responsible for having any required parental consent.]

## 4. What is public

When a director publishes a contest, a public copy is created. It contains contest name, dates, host and location, discipline, pilot display names, teams, the matrix, scores (including raw flight times and similar values printed on score sheets), rankings and when it was published. It does not contain email addresses, invitation links, audit history, review requests or other private director data.

Contests are first published as **Unlisted** (reachable by link, not searchable). The director may make them **Public** (searchable by anyone, including search engines).

Unlisted results carry the same details as public ones and can be opened by anyone with the link, including if the link is forwarded. The director, not the pilot, chooses what is published, so if you want your details removed, ask us (section 8).

Published results are a public record that others rely on. Copies may be cached or indexed by third parties, and we cannot recall those copies.

## 5. How we use data

To provide the service; to send invitations and verification codes; to secure the service and prevent abuse (rate limits, captcha); to fix bugs; to answer support requests; and to meet legal obligations. We do not use personal data for advertising or sell it.

## 6. Who we share it with

Service providers who process data for us, under their own terms:

- Auth0 (identity provider: sign-in, tokens; its tenant is in the United States). If you choose "Sign in with Google", Google also receives that sign-in.
- GitHub (source code and the downloadable Windows app; GitHub sees your download request)
- Cloudflare (website hosting, network protection)
- [Fly.io or Railway] (API server hosting)
- Neon (PostgreSQL database)
- [Email delivery provider, TBD] (invitations and codes)
- [Captcha provider, TBD] (support form)
- Vercel (privacy-friendly page-view analytics on the public website; to be re-evaluated at beta) [verify what Vercel Analytics stores and whether it sets cookies]
- [Email delivery provider, support channel: TBD, list when chosen]

Our hosts keep their own server logs under their own policies (method, path, status, IP address; we keep query strings and credentials out of our logs). Some of these are in the United States, so your data may be processed outside your country. We may disclose data when the law requires it or to protect the service and its users.

## 7. Retention

- Account data: until the account is erased (see section 8).
- Contest data: kept until the director deletes it or the account owner removes it.
- Guest identities: an unclaimed guest identity is removed 90 days after the contest it was invited to is completed, or 90 days after the contest's scheduled end date, whichever comes first. Records it made are kept and attributed to a "deleted user".
- Change log and audit history: [retention TBD; today kept until the contest data is deleted. Plan: fixed period, and scrub of personal fields for erased or redacted people].
- Deleted records are tracked for 90 days after sync so older changes cannot bring them back.
- Published results: kept until removed from public view by an administrator (see section 8). Request records are kept as the record of the decision.
- Verification codes: expire after 10 minutes.
- Support messages: 12 months after the last reply.
- Server logs at our hosts: 30 days or the host's shortest setting.
- Sync debugging records of rejected changes: 30 days. Audit history: 2 years after the contest is completed, with free-text reasons cleared after 90 days. Delist request reasons: cleared 1 year after the decision.
- Verification email of an anonymous publisher: deleted 30 days after the publication is claimed, delisted or removed.
- Backups: [TBD with hosting; verify Neon's retention]; deleted data can persist in backups until they age out.
- Inactive accounts: closed after 3 years without sign-in, with prior notice (may follow after the first release).


## 8. Your choices and rights

- **Visibility of your details.** With an account you choose whether you are listed in the pilot directory, whether directors see your email, and the public name shown in results (for example first name only).
- **How to exercise these rights (first release).** Access, correction, erasure, restriction, portability, objection, account closure, redaction of published results, and delisting are handled by email request to [privacy email] and carried out manually by an administrator; self-service tools are planned. We will confirm your identity first and answer within one month.
- **Close your account.** You can: (a) close the account only, keeping all data; (b) remove the data of contests you ran, which also asks an administrator to review removing your published contests from public view; or (c) remove your participation records, which automatically removes your details from published results. Your scores and placings remain, shown as private.
- **Pilots without an account.** Ask us (or the contest director) and an administrator will redact your details from published results.
- **Removing a published contest.** Published results are public record, so the director cannot remove them directly. An administrator reviews each request and may delist the contest.
- **Access, correction, deletion, and similar rights** under laws that apply to you (for example GDPR or CCPA): contact [privacy email]. We answer within [30 days]. Corrections to scores are made by the contest director.
- **Offline use.** Data in the Windows app is stored on your computer, in your user profile, and is only sent to us if you sign in and sync or publish.

## 8a. Where the law applies to you (GDPR and similar)

If you are in the European Economic Area, the UK or a similar jurisdiction:

- **Roles.** For the pilot details a contest director enters, the director is the controller and we are their processor. For accounts, sign-in, logs, the pilot directory and the public website, we are the controller.
- **Legal bases.** Running your account and syncing your contests: contract. Publishing results the director chooses to publish, security logs, support, and site statistics: our and the public's legitimate interest in an accurate, public sporting record and a secure service. You may object; where you object to being named in published results we will redact your details. [Add consent for analytics if Vercel sets cookies.]
- **Transfers.** Some providers (for example Auth0) process data in the United States. We rely on [EU-US Data Privacy Framework certification / standard contractual clauses; verify per vendor]. [If the database region can be in the EU, state it.]
- **Complaints.** You can complain to your local data protection authority.
- **Representative.** [EU/UK representative, if required, TBD with the legal entity.]

## 9. Security

Traffic is encrypted in transit. Pilot invitation links (emailed or printed as QR codes on score cards) stay valid until 24 hours after the contest is completed and are not used up when opened, so anyone who holds or photographs a card can use it; keep cards and links to yourself. Invitation credentials are random, stored only in protected form, and kept out of logs. Access to scoring is checked on the server on every write. No system is perfectly secure; report issues as described in SECURITY.md.

## 10. Cookies and similar technologies

[Verify before launch: Vercel Analytics is described as cookieless. If confirmed, state that the site sets no tracking cookies and needs no cookie banner; otherwise add consent.] The web apps keep your sign-in tokens in your browser's local storage; the Windows app keeps them in Windows' protected store. The self-scoring app will also hold a guest session on your device. Preferences are stored on your device.

## 11. Changes

We will post changes here and update the effective date. For material changes we will give notice in the apps or by email.

## 12. Contact

[privacy contact email, TBD] · Laminar Stack, [mailing address if required, TBD]
