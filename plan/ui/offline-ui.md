# RC Soar Score User Interface - Offline Application Frame

When the application is running in its offline wrapper there should be additional information shown to the user. This is presented as part of the outer application frame.

## Definitions

* Window - The actual OS window for the application.
* Application UI - The user interface as shown by the UI framework employed to build the interface.
* Main Content - When the majority of the application is placed within the application UI.
* Main Navigation - The area of the application dedicated to showing the main navigation constructs. Contained within the main content of the application.
* Application frame - Any application UI that wraps the main content of the application.

## Application Frame

The application frame is represented by any UI that is outside the main content of the application. Typically this UI "wraps" the main content. High-level UI constructs are presented here.

In the case of the offline application it will be used to display critical status information and provide action buttons.

## Connectivity Status

A spot in the application frame should be reserved to show status.

Status data points:

* Internet connectivity
* Remote system connectivity

## Sync Status

A spot in the application frame should be reserved to show if the local data is newer or older than the contest director's backed up data.

## Automatic Sync Toggle

The application should present a toggle for automatic syncing of data to the remote system. If this is toggled to "Manual" a manual sync button must be present to sync the data with the remote system.
