# Using a Basemap
EPANET-UI can display a basemap image behind the Network Map so that you can see the physical location of network objects. These images can come from either a static image file or from a dynamic web map service (WMS).  
<imgl images/Basemap.png>  

## Adding a Basemap
To add a basemap to the network map:
- Select ***Map > Basemap > Load*** from the Menu Bar.
- A ***Basemap Source Selection*** form will appear asking you to choose either an image file or a web map service for the basemap.
- If you choose to use an image file, a standard Open File dialog will appear where you can select a file stored in several different popular formats. Once selected, the image will appear centered in the map panel and scaled to maintain its aspect ratio.
- If you are starting a new project and choose to use a web map service then you will be prompted to provide the name of a location (such as a city) or a latitude and longitude where the initial location of your network will be centered.

NOTE:
If you want to use a web map service for an existing network then its coordinate reference system (CRS) must be identified with an EPSG code so that it can be displayed correctly over the basemap.

## Removing a Basemap
To remove a basemap, select ***Map > Basemap > Unload*** from the Menu Bar. You can also hide or show a loaded basemap using the ***Basemap*** check box that appears on the Map Legend.

## Adjusting the Basemap Image
Select ***Map > Basemap > Lighten*** from the Menu Bar to lighten the basemap image and ***Map > Basemap > Grayscale*** to display the basemap in grayscale.

The figure below contrasts an original basemap image with one lightened and converted to grayscale.
<imgc images/AdjustedBasemap.png>

## Georeferencing a Basemap
When a static basemap image file is added to a project it assumes whatever distance scaling and units that are in effect for the Network Map. For a new project these are arbitrarily set at 0 to 10,000 with no units assigned.

You can re-scale the basemap and assign it coordinate units (a process called georeferencing) by selecting ***Map > Basemap > Georeference*** from the Menu Bar. A ***Map Georeference Tool*** panel will appear above the Map Legend. It offers two options for georeferencing the basemap:
- Specifying the distance between two control points selected on the basemap image as well as the coordinates of a third selected point.
- Using a World file that contains a scaling factor (distance per image pixel) and coordinates of the image's top left corner in a plain text format.
Depending on your choice, the tool will take you through the steps of supplying it with the required information. After the basemap has been georeferenced the coordinates of all network objects previously appearing on the Network Map will be recomputed so as to maintain their relative position to one another.

## Aligning the Network and Basemap
When a static basemap image file is added to an existing project it may not align correctly with the objects already displayed on the Network Map. You can attempt to correct this manually by moving individual nodes as described in the <u>[Working with Objects]</u> topic, or you can request that EPANET-UI perform an automatic adjustment by pinning a set of nodes to specific locations on the basemap image.

To use the automatic alignment feature select ***Map > Basemap > Align*** from the Menu Bar. An ***Alignment Tool*** panel will appear above the Map Legend. The tool will ask you to select three network nodes to serve as control points along with the positions on the basemap where they should be located. It will then transform the coordinates of all of the other network objects to be consistent with how the coordinates of the control nodes were modified.

HINT:
Ideally the control nodes should be selected at known physical locations, such as at storage tanks or reservoirs, and should span a wide area of the basemap.
