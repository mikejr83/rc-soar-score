# RC Soar Score Public Site UI - Contest Not Found

There are a number of reasons the user may navigate to a specific contest's url and the contest cannot be displayed.

- Contest never existed - The user entered a bad contest id or the route beneath `/results/contests` doesn't exist.
- Contest was never published - A contest that has not been published has no public record. The page must not reveal whether a private contest exists.
- Contest is delisted - A system administrator approved a request to remove it from public view.

All of these cases should result in a standard informational page stating the contest or contest results could not be found.

This page should explain to the user that one of the following may have occurred:

- They may have entered a bad URL.
- The contest may not have been published yet. _A link to an unpublished contest should not normally be shared, but saying this helps assuage fears that a contest is not being published._
- The contest may have been removed from public view by a system administrator, at the request of its contest director.
