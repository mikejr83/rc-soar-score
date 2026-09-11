# RC Soar Score Public Site UI - Contest Search

The contest search screen will be a highly visited section of the public site. Its route should be deep-linkable, ie users should be able to bookmark it to go directly to searching for in-progress and completed contests. This public page shows only the published contest projection. It never edits private contest data and never exposes participant email, director audit history, pending mutations, or private review details.

A summary should be displayed indicating how many contests were completed or are in progress over the last 30 days.

A contest list is shown with a filter to enable users to find contests and subsequently view their ongoing progress or results.

This page will be located at the route: `/contests`.

## Contest List

A grid/list of contests should be present. By default, it should present the user with a list of the 10 most recent contests which are in-progress or completed.

The list should contain column data for the following:

* Start date of the contest
* Contest name
* Venue or location if provided

Indicators for each contest should include:

* In-progress
* Completed

## Filtering

The contests shown in the list may be filtered so users may easily find a specific contest. There are other default filters that will be always applied.

The following are filters that may be supplied by the user. An input that supports accepting the appropriate type of data will be displayed.

* Start date
* Name
* Venue

A default filter will be used for contests displayed regardless of what additional filtering the user provides. The contest list should not show delisted or deleted contests. It should not show any contest that is not published or that is private.

Contests may be created by contest directors for future dates. These could be inadvertently be published and publicly visible. Contest with future dates may only be shown when those contests are to be held through the following weekend, ie if today is Wednesday, contests starting Thursday through Sunday can be shown in the list. Contests with dates that would start the following Monday and into the future would not be shown.

## Actions

Other than filtering, the other actions available on this page are:

* Refreshing contests list - An eager viewer may be attempting to search for a contest before it has "gone live". A refresh button gives the user a way to refresh the list without refreshing the entire page.
* Selecting a contest - A user may select a contest in the list and go to the contest details.
