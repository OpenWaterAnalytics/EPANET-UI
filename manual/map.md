# Working with the Map

## Selecting a Theme to View
Node and link properties and their computed results can be viewed in color-coded fashion on the Network Map. To do so:
- Select the ***View*** tab on the Menu Bar.
- Use the ***Node Theme*** drop-down list to select a theme to view for network nodes.
- Use the ***Link Theme*** drop-down list to select a theme to view for network links.
- Click the ***Legend*** buttons to modify the colors used to display a theme.

## Zooming In or Out
- Select ***Map > Zoom In*** from the Menu Bar to zoom in on the center of the map.
- Select ***Map > Zoom Out*** from the Menu Bar to zoom out from the center of the map.
- You can also use the mouse wheel to zoom in by moving it forward or zoom out by moving it back. The zoom will be with respect to where the mouse pointer is located.

## Scrolling the Map
To scroll the map, move the mouse with the left button pressed.

## Viewing at Full Extent
Select ***Map > Full Extent*** from the Menu Bar (or click the <imgt images/extents.png> speed button) to view the Network Map at full extent.

## Re-Dimensioning the Map
To manually assign coordinates to the Network Map's bounding rectangle:
- Select ***Project > Setup*** from the Menu panel to bring up the <u>[Project Setup]</u> form.
- Select the ***Map*** tab on it and enter the new coordinates of the map's lower left and upper right corners. This will modify the coordinates of all network objects to fit within these boundaries yet keep their relative positions to one another the same.

NOTE:
The map cannot be re-dimensioned when a web map service is being used as a basemap.

## Locating an Object
To locate a specific object on the Network Map:
- Select ***Project > Locate*** from the Menu Bar.
- An ***Object Locator*** panel will appear above the Map Legend.
- Provide it with the type of object to find and its ID name.
- Press <kbd>Enter</kbd> to locate it on the map.

The ***Object Locator*** can also be asked to list all tanks, reservoirs, pumps, valves and water quality source nodes in the project.

## Submitting a Map Query
A Map Query can be used to highlight objects on the map that meet a specific criterion. To do so:
- Select ***Map > Query*** from the Menu Bar.
- A ***Map Query*** panel will appear above the Map Legend panel.
- Specify the criterion to be used and then press <kbd>Enter</kbd>.
- All map objects that meet the criterion will be colored in red while all others will be grayed out.
- The normal object coloring will return when the ***Map Query*** panel is closed.

## Change Map Display Settings
You can modify how objects on the network map are drawn:
- Select ***Map > Settings*** from the Menu Bar or right-click on any empty area of the Network Map.
- A ***Map Display Settings*** dialog will appear where you can select node and link sizes, choose what annotation to show, add flow direction arrows, and select a background color for the map.

## Exporting the Map
The image of the Network Map can be copied to the clipboard or saved to a file. Select ***Map > Export*** from the Menu Bar to make a ***Map Exporter*** panel appear above the Map Legend. Using this panel:
- Select to export the map to either the clipboard or to an image file.
- Indicate if you wish to include the Map Legend with the exported map or not.
- Click the panel's <ui2>Export</ui2> button to export the map.

If exporting to file, a standard Save File dialog will appear where you can choose an image format, a location and a name for the file.

## Toggling Auto-Length
The ***Auto-Length*** feature automatically computes the length of a newly added pipe using the dimensions assigned to the network map. The current ***ON/OFF*** status of ***Auto-Length*** is displayed with a check box in the Status Panel. It is set to ***OFF*** whenever a new project is begun or opened.
