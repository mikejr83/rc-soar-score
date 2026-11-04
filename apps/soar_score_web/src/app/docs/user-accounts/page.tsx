import type { Metadata } from "next";

import { Callout, DraftNote } from "@/components/docs/bits";
import { contestAppUrl } from "@/lib/site";
import { pageMetadata } from "@/lib/page-metadata";

export const metadata: Metadata = pageMetadata("I Need An Account?");

/** User account help (`/docs/user-accounts`).
 *  Source: plan/business-requirements/accounts.md, docs/adr/0001. */
export default function UserAccountsPage() {
  return (
    <>
      <p className="eyebrow">
        <b>Everyone</b> · Guide
      </p>
      <h1>I Need An Account?</h1>
      <p className="lede">Probably not. Here is who does, and why.</p>
      <DraftNote />

      <h2>Who needs nothing</h2>
      <ul>
        <li>
          <strong>Spectators.</strong> Published results are public; search and
          read them freely.
        </li>
        <li>
          <strong>Pilots entering scores.</strong> Your invitation link is your
          key. Behind the scenes you get a temporary guest identity so your
          entries are attributed to you; it is removed 90 days after the
          contest ends unless you claim it with an account.
        </li>
        <li>
          <strong>Directors running an offline contest.</strong> The Windows app
          stores everything locally. Even publishing works without an account:
          you confirm an email address with a one-time code.
        </li>
      </ul>

      <h2>Why a director would want one</h2>
      <ul>
        <li>Your contests and participant lists are backed up online and follow you between machines.</li>
        <li>Pilots can be found from the shared directory instead of typed in again.</li>
        <li>Anything you published anonymously with the same email becomes yours to manage.</li>
      </ul>

      <h2>Why a pilot would want one</h2>
      <ul>
        <li>Every contest you are invited to appears in one list without hunting for links.</li>
        <li>Directors can find you and copy your details, if you choose to be listed.</li>
        <li>You control how you appear in published results, for example first name only, and can follow your placings across directors.</li>
      </ul>
      <p>
        One account can be both: a director in your own club&apos;s events and a
        pilot in someone else&apos;s.
      </p>

      <h2>Register or sign in</h2>
      <p>
        This site has no sign-in of its own. Use the{" "}
        <a href={contestAppUrl}>contest administration app</a>; its sign-in
        page offers registration. If you open an invitation link as a pilot you
        can create the account from there and confirm that the named pilot is
        you, which attaches the scores you already entered.
      </p>

      <h2>Leaving</h2>
      <p>You choose what happens to your data:</p>
      <dl>
        <dt>Close the account only</dt>
        <dd>Nothing is deleted.</dd>
        <dt>Remove contest data</dt>
        <dd>
          Contests you ran are deleted. Published results stay, because they
          are public record; a request to remove them goes to a system
          administrator.
        </dd>
        <dt>Remove participation records</dt>
        <dd>
          Your name and details come off published results, which then show the
          pilot as withheld. Scores and placings stay.
        </dd>
      </dl>
      <Callout label="Coming">
        <p>
          A profile area on this site for account holders (own placings and
          stats) is planned for a later release.
        </p>
      </Callout>
    </>
  );
}
