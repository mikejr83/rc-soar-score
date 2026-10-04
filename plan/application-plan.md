# Plan: RC Sailplane Contest Soaring Application and Site

The goal is to build a set of applications that help contest directors and contestants for radio controlled sailplane contests to create, participate, and score the various types of radio controlled sailplane contests.

The solution is characterized by its ability for contest directors to either access a web site via the internet or through a local version of the application that can sync data after a connection is available and the user wishes to publish data. Participants will access the web site to enter scores.

A separate web application is provided for public viewing of contests and scores.

This creates the following main areas of concern for the initial application:

- Web application for managing and running contests
- Web application for hosting the project site along with access to published contests and scores.
- API layer for interacting with client applications
- Desktop shells for running the application in a stand-alone offline mode.

The following are personas interacting with the software:

- Contest Director - This is a user that is creating and configuring a contest. They will select pilots, can enter and modify scores, and do various administrative tasks with the contest they have created.
- Pilot - This is a user that is invited to a contest. They will enter their scores.
- Public Viewer - This is a user that is coming to the web site to view contests that are underway or have completed. They will want to see detailed information or overall results.

## Definitions

- Contest - A radio controlled soaring contest.
- Contest Director - A user who is running a RC soaring contest. They are responsible for creating the contest, configuring the parameters, and inviting pilots.
- Pilot - A participant in the contest.
- Pilot class - Pilot participants can be classified arbitrarily. Generally classifications are "senior", "junior", or "female".
- Round - A contest consists of many rounds where groups of pilots compete for scores.
- Group - A set of pilots flying against one another. Rounds typically are composed of one or more groups of pilots.
- Matrix - Pilots are organized into a set number of groups per round over the number of rounds in a contest. The matrix is how those pilots are allocated to each group in a round over the course of the contest. The goal of the matrix is to ensure to the best ability that each pilot competes against other pilots a similar number of times.

## General Design

The solution will be broken into several pieces to facilitate easy feature updates and fixes. The functionality centered around creating and running contests will be a single application. The public facing web site is separated because most of this functionality is only for viewing past and ongoing contest results.

### Online Contest Application

Many contest directors will have some ability to use internet during a contest. The application is to be written as a web application to enable users to access it without the need for any software installation. The web application should interact with an API layer to persist data.

Pilots will also interact with the web site during the contest. Participants are linked to the contest. The contest director will be able to configure online scoring during the contest setup. The pilots will directed to a the site to see their information and enter scores.

### Offline Contest Application

Often contests are run where there is no internet access. Therefore, the application should also be available as a native Flutter desktop application. This will enable contest directors to download an offline copy of the application before running their contest.

The contest director should be able to use the offline application to pull and push data to the API layer. A common use case is a contest director creating the contest when there is an internet connection, making the contest public, and opening the scoring. The contest proceeds where the only connection available is via mobile connections on pilot's mobile devices. They enter their scores via the web site. At the end of the contest contest director may use a hotspot to pull the latest data down to the application.

### Soar Score Site

The "RC Soar Score" site is the public face of the project. It will contain the information about this project, help and guides for using the software, and host the viewing of past and ongoing contests.

The main purpose for the site is for interested parties to view an ongoing contest or to retrieve results from past contests.
