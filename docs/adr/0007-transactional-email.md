# ADR 0007: Transactional email delivery

- Status: accepted for provider and environments
- Date: 2026-11-19
- Issues: [Support delivery #220](https://github.com/mikejr83/rc-soar-score/issues/220) and [Pilot invitation email #790](https://github.com/mikejr83/rc-soar-score/issues/790)

## Decision

- Use Amazon SES in US East (Ohio), `us-east-2`, for automated email from `rcsoarscore.com`. Ohio is available under the AWS account's regional policy. The base sending rate at selection was $0.10 per 1,000 emails with no monthly minimum. [SES pricing](https://aws.amazon.com/ses/pricing/)
- Send from `notifications@rcsoarscore.com`. Start with Easy DKIM and the default SES MAIL FROM. Cloudflare hosts the domain's DNS, including its existing DMARC policy, and forwards incoming mail for `support@rcsoarscore.com` and `test@rcsoarscore.com` to Gmail.
- Use two environments. Local development defaults to redirecting every outbound email to `test@rcsoarscore.com`. Explicitly enable live delivery in production with separate credentials. Keep provider credentials server-side. For local delivery, replace the complete recipient list, clear CC and BCC, add `[TEST]` to the subject, and scope the local SES credentials to the single test address so AWS enforces the restriction. Missing or invalid configuration must never enable live delivery. [SES recipient restrictions](https://docs.aws.amazon.com/ses/latest/dg/control-user-access.html#restrict-recipients)
- Use a fake sender for automated tests. Use the SES-to-Gmail route for deliberate manual delivery checks. Keep SMS outside this rollout.

## Verified on November 19, 2026

SES verified `rcsoarscore.com` and its DKIM records in Ohio. SES accepted a sandbox message from `notifications@rcsoarscore.com` to `test@rcsoarscore.com`, and Mike confirmed receipt in Gmail via Cloudflare. The app integration, production sending, and support reply workflow still need verification.

## Implementation order

1. **Build and test support delivery in #220.** Add a shared server-side mail sender that the hosted API can reuse for invitations. Wire the existing public form to a server endpoint with server-side CAPTCHA verification and rate limiting. Send only to the configured support address and set `Reply-To` to the validated submitter address in live mode. Use the test address for replies in redirect mode. Show confirmation after SES accepts the send. On failure, retain the form input and offer retry. Test accepted, rejected, and unavailable sends with a fake sender. Verify the app and error-screen links, the mailbox owner and reply workflow, and the 12-month retention rule after the last reply. Record the sender, forwarder, and receiving mailbox in the processor inventory under #645.
2. **Prepare production sending before live launch.** Set up an operator-visible path for delivery failures, bounces, and complaints. Request transactional production access in Ohio once that handling is in place and the account owner approves submission. Use separate production credentials and verify one controlled end-to-end support submission and reply after approval. Keep the email body, recipient addresses, and invitation credentials out of application logs. [SES production access](https://docs.aws.amazon.com/ses/latest/dg/request-production-access.html)
3. **Add pilot invitation email in #790 and coordinate resend with #791.** Reuse the sender and store the outcome per participant. A resend uses the existing link. Before implementation, reconcile #790's failed-send criterion with the invitation model, which distinguishes link issuance from delivery. Specify when a link is available for QR or copy after an immediate rejection, an uncertain result, or a later bounce. Preserve idempotent retries and the QR-only first field release. [Invitation requirements](../../plan/architecture-requirements/self-scoring-invites.md)
4. **Reuse the sender for later features.** Anonymous publisher verification (#213) and inactive-account warnings (#643) can use the same delivery setup when those workflows are implemented.
