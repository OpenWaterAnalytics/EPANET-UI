## EPANET-UI'S Workspace

The EPANET-UI workspace is shown in the picture below. It is divided into several panels that display program commands and information about the water distribution system being analyzed.

![](images/Workspace-8-Annotated.png)

The **Menu Bar** panel across the top of the workspace contains a collection of toolbars used to perform various program actions.

The **Speed Bar** panel along the right side of the workspace contains a toolbar for the most commonly used commands.

The upper portion of the **Project Explorer** panel is used to select a category of project data while its lower portion contains a **Property Editor** used to set the properties of an object belonging to the selected category.

The **Network Map** panel occupies the middle portion of the workspace. It displays the layout of the pipe network being analyzed and can include a basemap backdrop to show the network's physical location. Selecting an object on the map will load its current data values into the Property Editor.

The **Map Legend** panel shows the symbology used to color code themes displayed on the map. 

The **Status Bar** panel along the bottom of the workspace displays several key project options as well as the coordinates of the mouse pointer as it is moved across the Network Map.

## Program Preferences
<p>
Program preferences allow you to customize certain program features. To set program preferences click the ***File*** tab on the Menu panel and then select ***Preferences***. A ***Program Preferences*** dialog will appear from which you can select the following options:
</p>

| Preference               | Description                                                |
|--------------------------|------------------------------------------------------------|
|Blinking Map Marker  | Make the marker used to identify a selected map object blink on and off for a short period of time. |
|Flyover Map Hints     | Display the ID label and current theme value in a hint-style box whenever the mouse is placed over a node or link on the network map. |
|Confirm Deletions     | Display a confirmation dialog box before deleting any object. |
|Show Welcome Page at Start | Have a Welcome Page appear whenever EPANET-UI is started.|
|Open Last File at Start| Load the last project worked on when EPANET-UI starts.        |
|Automatic Backup File | Save a backup copy of a newly opened project to disk named with a .bak extension.|
|Use Blue Theme | Use a light blue background instead of light gray for all panels. |
|Clear Recent Files List | Clear the list of most recently opened project files from the File menu. |
|Numerical Precision   | Select the number of decimal places to display for computed results.|

The selected preferences will be saved and be applied when EPANET-UI is run again.
