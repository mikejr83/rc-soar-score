# RC Soar Score Public Site UI - Contest Not Found

There are a number of reasons the user may navigate to a specific contest's url and the contest cannot be displayed.

* Contest never existed - The user entered a bad contest id or the route beneath `/contests` doesn't exist.
* Contest is delisted

The cases for "Contest never existed" and "Contest is delisted" should result in a standard informational page stating the contest or contest results could not be found.

This page should explain to the user that one of the following may have occurred:

* They may have been entered a bad url.
* The contest may not have been published yet. *This technically should not happen but asserting this to a user is assuage fears that a contest is not being published.*
* The contest may have been removed by the system at the direction of a contest director.
