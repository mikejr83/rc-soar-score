# RC Soar Score User Interface

The visible applications will be built with Angular frontend framework. These applications will implement their UI and UX to the Material 3 standards. Thus, these applications will rely on the Angular Material control library.

The solution should use sass for styling. The implementation should rely on the styles and classes defined by the Angular Material library. Any custom formatting of styles should rely on existing variables defined in the Angular Material theme.

Any formatting that cannot conform to existing Angular Material style classes and require values not in the library's variable collection should define variables at the root of the application and reuse those as much as possible through the application's implementation. These values should be adjustable in the future to enable easy adjustment of the overall look and feel of the site.

The main contest administration pages should be designed to a minimum screen size of a tablet. These pages will contain a dense amount of configuration information or data grids. Text scaling should be taken into consideration. Uses of this application will often have vision requirements that make larger fonts desired. However, the site should still follow the standard Material guidelines.

The color layout for the administrative pages should be conducive for individuals viewing the pages on screens in bright sunlight.

The participant self-scoring screens should be designed with mobile-first consideration. The form inputs and navigation should be easy to use in a mobile browser. Again, theme colors and font choices should favor individuals viewing the content in bright, outdoor conditions, and with larger fonts.

## Application Frame

The application can be designed in such a way that navigation works from general screens, selecting an item, and then working towards detailed pages, view the items details. This concept will require a navigation construct that shows the user where they are within the application as well as a way for them to navigate to previous screens.

The application should maintain a status bar at the bottom of the application frame. This will serve multiple purposes.

If the user is utilizing the desktop application it will indicate if there is a network connection and the application can communicate with the remote API.

When a contest director has selected a contest it will contain the current overall status of the contest and scoring summary.

Scoring Summary:

* Latest round with scores.
* Latest group with scores.
* Number of pilots missing scores.
* Score Review Requests
