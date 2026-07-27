# Working with the Map

## Selecting a Theme to View
The controls on the ***Map Viewer*** panel allow you to view node and link properties and their computed results in color-coded fashion on the Network Map:
- Use the ***Node Theme*** and ***Link Theme*** drop-down lists to select themes to view.
- Use the  ***Legend*** check boxes to display Node and Link legends on the map. The legends can be repositioned by dragging them with the left mouse button pressed.
- Click the <imgt images/pencil.png> buttons (or right-click on the legends) to edit the colors and numerical ranges used for the selected themes.

## Selecting Map Layers to View
Use the check boxes on the Map Viewer panel to choose what categories of objects to view on the Network Map. These include an ***Overview Map*** check box that can display a small inset map on the Map Viewer panel showing the Network Map at full extent. It will contain a red rectangle around the area that the main map is zoomed in on. Dragging that rectangle to a new position will make the main map follow suit.

## Zooming In or Out
- Select ***Map > Zoom In*** from the Menu Bar (or click the <imgt images/zoom-in.png> speed button) to zoom in on the center of the map.
- Select ***Map > Zoom Out*** from the Menu Bar (or click the <imgt images/zoom-out.png> speed button) to zoom out from the center of the map.
- You can also use the mouse wheel to zoom in by moving it forward or zoom out by moving it back. The zoom will be with respect to where the mouse pointer is located.

## Panning the Map
To pan the map to a different area of its extent, move the mouse with the left button pressed.

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
- An ***Object Locator*** panel will appear above the Map Viewer panel.
- Provide it with the type of object to find and its ID name.
- Press <kbd>Enter</kbd> to highlight it and bring it into view on the map.

The ***Object Locator*** can also be asked to list all tanks, reservoirs, pumps, valves and water quality source nodes in the project.

## Submitting a Map Query
A Map Query can be used to highlight objects on the map that meet a specific criterion. To do so:
- Select ***Map > Query*** from the Menu Bar.
- A ***Map Query*** panel will appear above the Map Viewer panel.
- Specify the criterion to be used and then press <kbd>Enter</kbd>.
- All map objects that meet the criterion will be colored in red while all others will be grayed out.
- The normal object coloring will return when the ***Map Query*** panel is closed.

## Change Map Display Settings
You can modify how objects on the network map are drawn:
- Select ***Map > Settings*** from the Menu Bar or right-click on any empty area of the Network Map.
- A ***Map Display Settings*** dialog will appear where you can select node and link sizes, choose what annotation to show, add flow direction arrows, and select a background color for the map.

## Exporting the Map
The image of the Network Map can be copied to the clipboard or saved to a file. Select ***Map > Export*** from the Menu Bar and then choose ***To Clipboard*** or ***To File*** from the dropdown menu that appears.

If exporting to file, a standard Save File dialog will appear where you can choose a location and a name for the file. The map image will be saved in the PNG format.

## Toggling Auto-Length
The ***Auto-Length*** feature automatically computes the length of a newly added pipe using the dimensions assigned to the network map. The current ***ON/OFF*** status of ***Auto-Length*** is displayed with a check box in the Status Panel. It is set to ***OFF*** whenever a new project is begun or opened.
