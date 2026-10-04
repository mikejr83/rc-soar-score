# RC Soar Score Architecture - Offline Usage

The RC Soar Score application has the ability to be run via the internet or as a native Flutter desktop application. The offline usage of the application is provided to users where they wish to have the complete ability to run a contest without the need to be connected to the internet. There are many reasons for this. Chief among them is that many soaring contests take place in locations with limited mobile data connections. This means that contest directors will need to create, configure, and score contests without any participants providing scoring data.

## Goals

The following sections details the goals and requirements for the offline usage of the RC Soar Score application.

### Front-End Parity

The online and offline versions of RC Soar Score should effectively be the same. Both are built from the same Flutter code base: the web build is the online application and the native desktop build is the offline application. The same API layer and domain logic serve both, so the two behave identically.

- **Web application.** The web application stores no contest data in the browser. All contest data is read and written through the API. The browser may use IndexedDB (or similar browser storage) for user preferences and specific front-end client functionality, but never for the data defined in the [data model](data.md).
- **Native application.** The native application hosts the same API layer in-process and stores all contest data locally. The application's UI talks to that local API exactly as the web application talks to the remote one.

### Connected Operation

The native application is not designed to operate solely offline. When it has an internet connection and can reach the remote API, it behaves as follows:

1. **Initial sync.** The application synchronizes first, so that the local data and the remote data are in the same state. This follows the [synchronization requirements](offline-synchronization.md).
2. **Write-through.** From that point forward, a change is applied to the local data first and then immediately sent to the remote API. The change is recorded as a pending mutation until the service acknowledges it.
3. **Disconnection.** If the connection is lost or the remote API cannot be reached, the application continues to operate on local data. Pending mutations are retained and sent on the next successful connection, which begins with another synchronization.

Local-first means the director never waits on the network to enter or change data.

### Publishing Results

The contest director using the offline application may still desire to have a record of the contest entered into the public site. Publishing results is the act of the contest director taking a contest which was create, configured, administered, and completed while using the offline application and sending the contest results to the public site.

This functionality differs from syncing contest director data to the remote system. A contest director may create a contest and perform many actions with it offline. The application may detect an internet connection and connectivity to the remote system. The application will enable the contest director to sync their data for backup. This does not publish results.

Further, the contest director may be performing most contest actions offline. They may connect and publish a contest which is currently underway and not completed. The contest could then continue and the contest director come back online and publish a final update.

#### User Accounts

If the contest director has a user account then the contest can be published simply by the act of the contest director requesting the contest to be published.

Publishing contest results does not require the contest director to create a user account, however. The goal of the application is to encourage its use and not to present artificial walls to having contest results being presented to the public. For an unregistered contest director to publish results it will be necessary for the contest director to provide an email. The email will be verified using a code. When the contest director verifies the code they will be able to publish the contest.

### Syncing Application Data

The offline application is **not** designed to solely operate offline. It is designed that it can operate offline without losing the core ability to administer a contest. The application should sync data back to the remote system when it is available. This enables the application to recover data in the event of catastrophe where the offline application is located.

## Stretch Goals

There are other reasons to have an offline version of the RC Soar Score application. These sections outline various future plans.

### External Timer Integration

Other scoring applications present the ability to manage external timers. External timers are hardware devices that convey audio and visual information about the contest.

This feature would enable the application to configure and interface with various timer implementations.

The following will need to be done:

- An analysis of the current timing systems utilized by contest directors must be completed. This is to determine what systems will be supported by RC Soar Score.
- An understanding of what is necessary to configure them will need to be cataloged.
- How the application interacts with the timers will need to be defined. This includes if the application is driving the timer functionality or if the timer is taking configuration and then providing feedback to the application.
- The manner in which the application interfaces with these systems will need to be designed. Many of the timers require communication over USB, Bluetooth, etc.
