# Working with Projects
An EPANET project contains all of the information used to model a network. It is stored in a plain text file that contains tables describing the different categories of network data and is usually named with a .INP extension. 

## Creating a New Project
To create a new project:
1. Select ***File > New*** from the Menu Bar or click the <imgt images/new.png> speed button. 
2. You will be prompted to save any currently opened project if changes were made to it.
3. A new, unnamed project is created with all options set to their default values.
4. The <u>[Project Setup]</u> form will appear allowing you to override default options.

## Opening an Existing Project
To open an existing project:
1. Click the Menu Bar's ***File*** tab.
2. If the project's file name appears on the list of recent projects then select it.
3. Otherwise select ***Open*** to have a standard Open File dialog form appear from which you can select a project file to open.

Clicking the <imgt images/open.png> speed button is another way to open a project file. You can also drag and drop a file from the operating system's File Explorer or File Manager onto any area of the EPANET-UI workspace.

## Saving a Project
To save a project under its current name select ***File > Save*** from the Menu Bar or click the <imgt images/save.png> speed button..

To save a project using a different name:
1. Select ***File > Save As*** from the Menu Bar.
2. Select a folder and file name from the standard Save File dialog that appears.

## Setting Project Defaults
Each project has a set of default values that are used unless overridden. These values fall into four categories:
- prefixes for ID labels (labels used to identify nodes and links when they are first created)
- node/link properties (e.g., node elevation, pipe length, diameter, and roughness)
- hydraulic analysis options (e.g., system of units, head loss formula, etc.)
- coordinates of the Network Map's bounding rectangle.
To set default values for a project:
1. Select ***Project > Setup*** from the Menu Bar.
2. A <u>[Project Setup]</u> form will appear with pages for each category listed above.
3. Check the box in the lower right if you want to to save your choices for all new future projects.
4. Click ***OK*** to accept your choice of defaults.
The ***Project Setup*** form will also appear whenever a new project is created.

## Viewing a Project Summary
To view a project summary select ***Project > Summary*** from the Menu Bar.

## Viewing All Project Data
To view all project data select ***Project > Details*** from the Menu Bar. A form will appear with project data listed by category in a collection of non-editable tables in the same format used to save the project to file.
