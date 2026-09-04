# RC Soar Score Architecture - Contest Publishing

The RC Soar Score application has the ability to be run via the internet or as a local application wrapped in a desktop shell (like Electron). The concept of publishing relates to users of the application in the desktop shell context.

The goal of the system is that desktop version of the app can function completely without an internet connection. If a connection becomes available to the application it should enable the contest director or user the ability to sync data back to the remote site. This is so that any data that was generated in the local environment is backed up.

The term publishing refers to the process of synching the local data to the remote system. This term does not describe a contest lifecycle state.

## Syncing Data

The contest director using the application in an offline mode can create a contest and perform all operations to run the contest without the need to be connected to the internet. At some point it they may wish to "publish" their data to the remote site for backup purposes or to make the contest available for public viewing.

A contest that is created offline will not be sent to the remote site for storage unless the contest director has a user account with the site. The contest director will need to indicate that they wish to publish the locally created contest to the remote site.

Contests that were created when the contest director is using the web application connected to the internet will require the contest director to have a user account and the contest is synced automatically. If the contest director latest goes to their offline version of the application while connected to the internet the contest will be pulled from the remote site. Any changes that were made to the contest while offline will be pushed to the remote site on the next connection.
