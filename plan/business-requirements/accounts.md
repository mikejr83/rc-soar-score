# RC Soar Score Business Requirements

The RC Soar Score solution is a set of applications and APIs to track, score, and publish results for radio controlled sailplane contests. The users of the software may create accounts in order to use various functions of the software.

## Non-Account Functionality

A contest director using the offline capabilities of the application will not need any account. The data is stored locally. The contest director is the owner and can modify the data such as the scoring. If the director later creates an account or signs in, the data created offline becomes theirs on the remote system.

Participants can be invited to enter scores online. These users are not required to create an account. The application should generate a special URL that is sent to the participant. Behind the scenes the system gives such a participant a temporary guest identity so that their entries can be attributed. If they later create an account, what they did can be attached to it.

Users viewing the public contests do not need an account.

A contest director who has no account may still publish the results of a contest. They provide an email address and confirm it with a code. If they create an account with that same email later, they can take over management of what they published.

## Account Related Functionality

Contest directors can create accounts. This will enable the syncing of any offline data to the remote system.

Participants can create accounts. This enables contest directors to search and find them from an online database to add to contests. A participant chooses whether to be listed, and whether directors can see their email. A director who finds them copies their details into the director's own participant records, which stay private to that director.

A participant with an account also controls how they appear in published results. They can show a public name of their choosing, for example only their first name. They can follow their results across the contests of different directors after confirming that those directors' participant records are theirs. Creating an account never changes a director's records or past contests by itself.

A person can be both a contest director and a participant in someone else's contest with the same account.

## Closing an account

A person who wants to leave chooses what happens:

- **Close the account only.** Nothing is deleted.
- **Remove contest data.** The data of the contests they ran is deleted. Published results stay on the public site, and a request to remove them is sent to a system administrator for review.
- **Remove participation records.** Their details are removed from published results automatically, which then show that the details are private. Their scores and placings in the results remain.

A contest director's data is not removed because someone else asks. Published results are public record, so a director cannot remove them directly. A system administrator decides whether a published contest is removed from public view.

## System Administrators

A system administrator is a trusted user set up by the system's operators. They review requests to remove published contests from public view, and they can remove a participant's details from published results when that participant has no account.
