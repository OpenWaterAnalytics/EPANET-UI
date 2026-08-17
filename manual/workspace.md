## EPANET-UI'S Workspace

The EPANET-UI workspace is shown in the picture below. It is divided into several panels that display program commands and information about the water distribution system being analyzed.

![](images/AnnotatedWorkspace.png)

The **Menu Bar** panel across the top of the workspace contains a collection of toolbars used to perform various program actions.

The **Speed Bar** panel at the top right of the workspace contains a toolbar for the most commonly used commands.

The right hand side of the workspace contains the **Project Explorer** panel. Its upper portion is used to select a category of project data while its lower portion contains a **Property Editor** used to set the properties of an object belonging to the selected category.

The **Network Map** panel occupies the middle portion of the workspace. It displays the layout of the pipe network being analyzed and can include a basemap backdrop to show the network's physical location. Selecting an object on the map will load its current data values into the Property Editor.

On the left hand side of the workspace is the **Map Viewer** panel. It controls what themes, legends and layers are displayed on the network map.

The **Status Bar** panel along the bottom of the workspace displays several key project options as well as the coordinates of the mouse pointer as it is moved across the Network Map.

Not shown is the **Report Panel** that shares space with the Network Map panel and displays the contents of output reports selected from the **Project** menu. The **View** radio buttons on the Map Viewer are used to switch between the two panels.

## Program Preferences
<p>
Program preferences allow you to customize certain program features. To set program preferences click the <b>File</b> tab on the Menu panel and then select <b>Preferences</b>. A <b>Program Preferences</b> dialog will appear from which you can select the following options:
</p>

| Preference               | Description                                                |
|--------------------------|------------------------------------------------------------|
|Blinking Map Marker  | Make the marker used to identify a selected map object blink on and off for a short period of time. |
|Flyover Map Hints     | Display the ID label and current theme value in a hint-style box whenever the mouse is placed over a node or link on the network map. |
|Confirm Deletions     | Display a confirmation dialog box before deleting any object. |
|Show Welcome Page at Start | Have a Welcome Page appear whenever EPANET-UI is started.|
|Open Last File at Start| Load the last project worked on when EPANET-UI starts.        |
|Automatic Backup File | Save a backup copy of a newly opened project to disk named with a .bak extension.|
|Clear Recent Files List | Clear the list of most recently opened project files from the File menu. |
|Numerical Precision   | Select the number of decimal places to display for computed results.|

The selected preferences will be saved and be applied when EPANET-UI is run again.
