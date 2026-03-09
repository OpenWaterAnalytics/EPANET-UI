# Introduction

<p>
This tutorial introduces you to using EPANET-UI to analyze the hydraulic and water quality behavior of piping networks. The topics to be covered include:
</p>

- Project Setup

- Drawing the Network

- Setting Object Properties

- Saving and Opening Projects

- Running a Snapshot Analysis

- Running a Pressure Driven Analysis

- Running an Extended Period Analysis

- Running a Water Quality Analysis

But first we will provide a quick overview of EPANET-UI's workspace to help you become familiar with its layout.

NOTE:
More detailed information on modeling water distribution systems can be found in the following publications:
- AWWA's <i>M32 Computer Modeling of Water Distribution Systems</i> is a good introduction to the topic.
- <i>Advanced Water Distribution Modeling and Management</i> is a more comprehensive reference.

# EPANET-UI's Workspace

The EPANET-UI workspace is shown in the picture below. It is divided into several panels that display program commands and information about the water distribution system being analyzed.

![](images/workspace-8-annotated.png)

The **Menu Bar** panel across the top of the workspace contains a collection of toolbars that execute various program commands.

The **Speed Bar** panel at the top right of the workspace contains a toolbar for the most commonly used commands.

The upper portion of the **Project Explorer** panel is used to select a category of project data while its lower portion contains a **Property Editor** used to set the properties of an object belonging to the selected category.

The **Network Map** panel occupies the middle portion of the workspace. It displays the layout of the pipe network being analyzed and can include a basemap backdrop to show the network's physical location.

The **Map Legend** panel shows the symbology used to color code themes displayed on the map. 

The **Status Bar** panel along the bottom of the workspace displays several key project options as well as the coordinates of the mouse pointer as it is moved across the Network Map.


# Project Setup

<p>
We will analyze the simple water distribution system shown below. It consists of a source reservoir (e.g., a treatment plant clearwell) from which water is pumped into a two-loop pipe network. There is also a pipe leading to a storage tank that floats on the system.
</p>

<imgl images/network.png> <br>

<p>
Our first task is to create a new project in EPANET and make sure that certain default options are selected.
</p>

1.Launch EPANET-UI.

2.If a Welcome Page appears, select the option to create a new project. If you previously disabled the Welcome Page from showing on startup, select <b>File > New</b> from the Menu Bar.

3.A <b>Project Setup</b> dialog form will appear that contains four pages, two of which are shown below.

<imgl images/setup.png><imgl images/setup2.png><br>

4.On the <b>Options</b> page of the form choose `gpm` as Flow Units and Hazen-Williams (`H-W`) as Head Loss Formula.

5.On the <b>ID Labels</b> page, clear all of the ID Prefix fields. This will make EPANET automatically label new objects with consecutive numbers.

6.On the <b>Properties</b> page set the Pipe Roughness to `100`.

7.Click <ui2>  OK  </ui2> to accept these choices and close the form.

<p>
If you wanted to save these choices for all future new projects you could check the Save box at the bottom of the form before accepting it.
</p>

<p>
Next we will set some map display options so that ID labels will be displayed as we add objects to the network, as will the symbols for these objects. Select <b>Map > Settings</b> from the Menu Bar (or simply right-click on the Map Panel). A <b>Map Display Settings</b> dialog will appear.
</p>

<imgl images/mapsettings.png>

1.On the <b>Annotations</b> page of the dialog select <i>Show node IDs</i>, <i>Show link IDs</i>, and set the Font size to `10`.

2.On the <b>Nodes</b> page set the <i>Size</i> to `6` and on the <b>Links</b> page set the <i>Size</i> to `2`.

3.Click <ui2>  OK  </ui2> to close the form.

# Drawing the Network 

<p>
We are now ready to construct our example pipe network.
</p>

NOTE:
Drawing objects on the map is just one way of creating a network. You can also import a network layout from GIS shapefiles, CAD DXF files or from tab delimited files. Please consult the EPANET-UI manual for more details.

## Adding Nodes

<p>
We begin by adding nodes. Select <b>Project > Add</b> on the Menu Bar and select <b>Reservoir Node</b> from the drop-down menu that appears.
</p>
<imgc images/addresv.png>
<p>Then left-click the mouse on the map at the location where the reservoir belongs and press <kbd>Esc</kbd> (or right-click) to quit adding Reservoir objects.
</p>

<p>
Next we will add the junction nodes. Again select <b>Project > Add</b> and this time select <b>Junction Node</b> from the drop-down menu. Then left-click on the map at the locations of nodes 2 through 7, as shown in the figure below. When done, hit the <kbd>Esc</kbd> key.
</p>

<imgl images/nodes.png><br>

<p>
Finally add the tank by selecting <b>Tank Node</b> from the <b>Project > Add</b> button's drop-down menu and clicking the map where the tank is located. Note how sequential ID labels are generated automatically as new objects are added to the network.
</p>

## Adding Links

<p>
Now that we have finished adding nodes to our network we can proceed to add links so that our network will look as follows:
</p>

<imgl images/links.png><br>

1.Once again select <b>Project > Add</b> on the Menu Bar but this time select <b>Pipe Link</b> from the drop-down menu.

2.Beginning with Pipe 1, left-click the mouse pointer on Node 2 and then on Node 3. Notice how an outline of the pipe is drawn as you move the mouse from Node 2 to 3.

3.Repeat Step 2 for pipes 2 through 7.

4.Pipe 8 is curved. To draw it, left-click the mouse first on Node 5. Then as you move the mouse towards Node 6, left-click at those points where a change of direction is needed to maintain the desired shape. Complete the process by left- clicking on Node 6.

5.Press <kbd>Esc</kbd> (or right-click) to end adding pipes.

<p>
Finally we need to add pump link 9. Click the <b>Add</b> button once again and this time select <b>Pump Link</b> from the drop-down menu. Then left-click the mouse first on Node 1 and then on Node 2 and hit <kbd>Esc</kbd> to end.
</p> 

## Adding Labels

The final task in building our network is to add some descriptive labels. Once again select <b>Project > Add</b> on the Menu Bar and then select <b>Map Label</b> from the drop-down menu. Move the mouse to the map location where the label should appear and left-click. An edit box will appear in which you can enter the text of the label.

<imgl images/labels.png><br>

<p>
 Press <kbd>Enter</kbd> to accept your entry (or <kbd>Esc</kbd> to cancel it). Repeat this procedure for all of the network labels and finally hit <kbd>Esc</kbd> to quit. The result should look as follows:
</p> 

 <imgl images/network.png>

## Re-Positioning Objects

<p>
At this point we have completed drawing the example network. Your network should look like the one shown above. If the nodes are out of position you can move them around by clicking the node to select it, and then dragging it with <kbd>Ctrl</kbd> + <mbl> pressed to its new position. You can also use <kbd>Ctrl</kbd> + an arrow key to move the node more precisely. The labels can be repositioned in similar fashion.
</p>

<p>
To reshape the curved pipe 8 select <b>Edit > Reshape Link</b> on the Menu Bar. This will display the vertex points of the link as small squares. Follow the instructions in the panel that appears above the Map Legend to add, delete or move vertices.
</p>

<imgc images/shapelink.png>

# Setting Object Properties

As objects are added to our project, EPANET-UI assigns them a default set of properties. When an object is selected on the map we can edit its properties using the <b>Property Editor</b> (the lower right panel in <a>EPANET-UI's Workspace</a>).

## Setting Node Properties

The nodes in our example network have the following elevations and base demands:

<grid>
<gr> <gd><b>Node</b></gd><gd><b>Elevation (ft)</b></gd><gd><b>Base Demand (gpm)</b></gd></gr>
<gr> <gd>1</gd><gd>700</gd><gd>0</gd></gr>
<gr> <gd>2</gd><gd>700</gd><gd>0</gd></gr>
<gr> <gd>3</gd><gd>710</gd><gd>150</gd></gr>
<gr> <gd>4</gd><gd>700</gd><gd>150</gd></gr>
<gr> <gd>5</gd><gd>650</gd><gd>200</gd></gr>
<gr> <gd>6</gd><gd>700</gd><gd>150</gd></gr>
<gr> <gd>7</gd><gd>700</gd><gd>0</gd></gr>
<gr> <gd>8</gd><gd>830</gd><gd>0</gd></gr>
</grid>


<imgl images/editor.png>

Let's begin with Junction Node 2. After clicking on it, its properties will appear in the Property Editor. Enter an elevation of `700` and a base demand of `0`. Proceed in a similar fashion for nodes 3 through 7.

NOTE:
Instead of clicking on each node you can use the Left/Right arrow buttons on the Property Editor to move to the previous or next node.

For the Reservoir (Node 1), enter an elevation of `700`. For the tank (Node 8), enter `830` for its elevation, `4` for its Initial Depth, `20` for its Maximum Depth, and `60` for its Diameter.

## Setting Link Properties

The pipes in our example network have the following lengths and diameters:

<grid>
<gr> <gd><b>Pipe</b></gd><gd><b>Length (ft)</b></gd><gd><b>Diameter (in)</b></gd></gr>
<gr> <gd>1</gd><gd>3000</gd><gd>14</gd></gr>
<gr> <gd>2</gd><gd>5000</gd><gd>12</gd></gr>
<gr> <gd>3</gd><gd>5000</gd><gd>8</gd></gr>
<gr> <gd>4</gd><gd>5000</gd><gd>8</gd></gr>
<gr> <gd>5</gd><gd>5000</gd><gd>8</gd></gr>
<gr> <gd>6</gd><gd>7000</gd><gd>10</gd></gr>
<gr> <gd>7</gd><gd>5000</gd><gd>6</gd></gr>
<gr> <gd>8</gd><gd>7000</gd><gd>6</gd></gr>
</grid>

with all Roughness factors having been set to `100` using the <a>Project Setup</a> dialog.

<p>
Following the same procedure used for nodes, simply click on each pipe (or use the Editor's arrow buttons) to move from pipe to pipe to enter its properties into the Property Editor.
</p>

## Adding a Pump Curve

<p>
For the pump (Link 9) we need to assign it a pump curve (head versus flow relationship).
</p>

1.Click on the pump link 9.

2.In the Pump Curve field of the Property Editor, click the ellipsis button <ui2>...</ui2> (or simply press <kbd>Enter</kbd>).

3.In the <b>Data Curve Selector</b> dialog that appears click the <b>Add</b> button.

<imgl images/addpump.png><br>

4.In the <b>Data Curve Editor</b> dialog that next appears, select <b>Pump</b> for Curve Type and enter our pump's design point of `600` gpm flow at `150` ft of head. EPANET-UI will automatically create a complete pump curve from this single point and display its shape.

<imgl images/editpump.png> <br>

5.Click <ui2>  Accept  </ui2> on the Data Curve Editor to close it and click <ui2>  OK  </ui2> on the Data Curve Selector dialog to close it. The Property Editor will then show that Curve 1 has been assigned as Pump 9's pump curve.

# Saving and Opening Projects

Having completed the initial design of our network it is a good idea to save our work to a file at this point.

1.Select <b>File > Save As</b> from the Menu Bar.

2.In the <b>Save As</b> dialog that appears, select a folder and file name under which to save this project. We suggest naming the file <b>tutorial.inp</b>. (An extension of .inp will be added to the file name if one is not supplied.)

3.Click <ui2>OK</ui2> to save the project to file.

<p>
The project data is saved to the file in a readable text format. You can view its contents by selecting <b>Project > Details</b> on the Menu Bar.
</p>

<p>
To open the project at some later time, you would select <b>File > Open</b>.
</p>

# Running a Snapshot Analysis

We now have enough information to run a single period (or snapshot) hydraulic analysis of our example network. To run the analysis select <b>Project > Analyze</b> on the Menu Bar.

<p>
If the run was unsuccessful then a <b>Status Report</b> window will appear indicating what the problem was. If it ran successfully you can view the computed results in a variety of ways. Try some of the following:
</p>

- Select <b>Pressure</b> from the Node Theme list box on the <b>View</b> tab of the Menu Bar to view computed nodal pressure in color-coded fashion. Click its associated <b>Legend</b> icon if you want to change the theme colors and their intervals.

<imgl images/viewmaptheme.png><br><br>

- Click on any node or link and note how its computed results are displayed at the end of the Property Editor. 

- Create a tabular listing of results by selecting either a <b>Node Results Table</b> or <b>Link Results Table</b> report from the drop-down menu of the <b>Report</b> button on the <b>Project</b> tab of the Menu Bar.

<imgl images/nodesreport.png><br>

# Running a Pressure Driven Analysis

The previous analysis was made under the requirement that stipulated nodal demands must be met no matter what pressures may result. This is referred to as Demand Driven Analysis (<b>DDA</b>) and is the classical approach to computing pipe network hydraulics. However meeting this condition mathematically may produce pressures that in reality are too low to provide the required demand and may even be negative.

<p>
We can see an example of this by changing the demand at Node 5 of our example to a fire fighting requirement of `1000` gpm. Running the model again will result in the demand being met but at an unrealistic pressure of -47 psi.
</p>

<p>
Pressure Driven Analysis (<b>PDA</b>) is an alternative to DDA that allows demand to be a function of pressure. Delivered demand is zero when pressure is below a minimum level and is at its full nominal value when some service pressure is exceeded. In
 between these levels demand varies as a power function of pressure. 
</p>

<p>
The EPANET solver can perform a pressure driven analysis on our fire flow modified example network by taking the following steps:
</p>

<imgl images/pda.png>

1.In the <b>Project Explorer</b> panel select the <b>Demands</b> category of Analysis Options.

2.In the <b>Property Editor</b> for this category, set the Demand Model to `PDA` and the Service Pressure to `20`.

3.Re-run the analysis.

4.Select Node 5 and view its results in the Property Editor. We see that the actual demand delivered is only 712 gpm instead of 1000 but at a positive pressure this time  of 10 psi. The deficit in demand is 29 percent.

5.Restore the base demand at Node 5 to its original value of `200` gpm and the Demand Model to `DDA` in preparation for running the next type of analysis we will examine - an extended period simulation.
<br>

NOTE: EPANET-UI can also run an automated fire flow analysis where it will determine for a designated group of nodes the demand that just meets a required pressure level (20 psi in this example). Please consult the EPANET-UI manual for details.


# Running an Extended Period Analysis

An extended period analysis makes demands and system operation vary over the course of a day or more. EPANET uses periodic time patterns to change nodal demands at fixed intervals of time. It can also use control rules to change pump and valve settings for specific times or system conditions.

<p>
For our example network we will use a typical diurnal pattern of water consumption. It will apply a multiplier to the base demand of each junction that will result in demands changing at each hour of the day. To setup the project for a extended period run:
</p>

<imgl images/selecttimes.png><imgl images/edittimes.png>

1.In the <b>Project Explorer</b> panel select the <b>Times</b> category of Analysis Options.

2.In the <b>Property Editor</b> for this category, set the Duration to `72` hours.

3.Leave the Pattern Step at the default value of `1:00` hour.
<br>

Then add a time pattern for our junction demands:

1.In the <b>Project Explorer</b> panel select the <b>Demands</b> category of Analysis Options.

2.In the Default Pattern field of the Property Editor, click the <ui2>...</ui2> button (or press <kbd>Enter</kbd>).

3.In the <b>Time Pattern Selector</b> dialog that appears, click the <ui2>Add</ui2> button.

<imgl images/addpattern.png><br>

4.In the <b>Time Pattern Editor</b> dialog that next appears, click the `Use typical diurnal pattern` label as shown below. This will populate the pattern with a set of 24 multipliers with low demands during night time hours and two periods of high demands during the morning and early evening hours. (In practice, one should use actual water usage data to establish a site-specific demand pattern).

<imgl images/patterneditor.png><br>

5.Click <ui2>  Accept  </ui2> to close the Time Pattern Editor and then click <ui2>  OK  </ui2> on the Time Pattern Selector dialog to close it

<p>
Pattern 1 has now been assigned as the default demand pattern for all junction nodes in our example. Its multipliers are used to modify the demand from its base level in each time period. Since we are making a run of 72 hours, the pattern will wrap around to the start once again after each 24-hour interval of time.
</p>

<p>
We are now ready to run the extended period hydraulic analysis. Once again select <b>Project > Analyze</b> from the Menu Bar.  For extended period analysis you have several more ways in which to view results:
</p>

- Select the <b>View</b> Menu Bar tab and use the slider control to display the network map at different points in time. 

- Click the <b>Animate</b> button next to the slider control to animate the map through time. Click it again to stop the animation.

<imgl images/epsview.png><br>

- Create a time series plot for any node or link. For example, to see how the water elevation in the tank changes with time:

  1.Click the map on tank Node 8.

  2.Select <b>Project > Report > Time Series Report</b>.

  3.A <b>Time Series Selector</b> panel will appear above the Map Legend with a time series for Tank 8's pressure listed. Since we want to plot water surface elevation (i.e., hydraulic head) click the <imgt images/pencil.png><b>(Edit)</b> button so we can change the variable to be plotted.

  4.On the new page of the Time Series Selector that appears, select <b>Head</b> as the parameter to plot and hit <ui2>  Accept  </ui2> to return to the time series list page.

<imgl images/timeseries1.png><imgl images/timeseries2.png><br>

  5.Click <ui2>  View  </ui2> to view the time series of hydraulic head at tank Node 8. It should look something like the figure below.

<imgl images/timeseries3.png><br>

# Running a Water Quality Analysis

<p>
We will now extend the analysis of our example network to include water quality.
</p>

## Water Age Analysis

<p>
The simplest type of water quality analysis to run is tracking the age of water throughout the network over time. To make this analysis for our example:
</p>

1.In the <b>Project Explorer</b> panel select the <b>Quality</b> category of Analysis Options.

2.In the <b>Property Editor</b> for this category click the <ui2>...</ui2> button (or press <kbd>Enter</kbd>) in the Single-Species data field.

3.A <b>Single Species Water Quality Editor</b> dialog will appear. Select `Water Age` for the choice of Type of Quality Analysis and close the dialog.

4.Run the analysis.

5.To visualize the growth of water age over time, select <b>Water Age</b> as the map's Node and Link themes on the <b>View</b> tab and click the <b>Animate</b> button. 

<p>
If you create a time series plot for Water Age for the tank Node 8 you will see that unlike water level, 72 hours is not enough time for the tank's water age to reach a periodic behavior when it begins with an initial age of 0. Try repeating the analysis after setting the tank's <i>Initial Quality</i> to `84` (you can leave the time series plot open while doing this -- it will refresh after the new run is completed).
</p>

<p>
Afterwards, reset the tank's <i>Initial Quality</i> to `0` once again in preparation for the next analysis.
</p>

## Chlorine Decay Analysis

<p>
Next we will show how to simulate the transport and decay of chlorine disinfectant throughout our example network. To do this you need to make the following changes to the project:
</p>

<imgl images/cl2quality.png>

1.Re-open the <b>Single Species Water Quality Editor</b> as you did when analyzing Water Age.

2.Change the Type of Quality Analysis to `Chemical`. Note how the editor expands to display additional options used for modeling a chemical.

3.Enter `Chlorine` for the Constituent Name and select `mg/L` for its concentration units.

4.Leave the other options at their default values and close the editor.

<p>
Next we need to specify the coeffcients that determine the rate at which chlorine decays as it travels through the system. For this example we will assume that chlorine decay is a first-order reaction (the default option) that occurs only in the bulk flow (wall reaction will not be considered), and has a rate coefficient of -1.0/day.
</p>

<p>
We now need to select each pipe in the network and in the Property Editor set its <i>Bulk Coeff.</i> property to `-1.0`. Since chlorine also decays in the storage tank we need to select that node (Node 8) and set its <i>Reaction Coeff.</i> property to `-1.0` as well. Finally, we need to specify a source concentration of chlorine that enters the network. The simplest way to do this is to set the <i>Initial Quality</i> property of the reservoir Node 1 to a value which we will take as `1.0` mg/L.
</p>

NOTE:
An easier way to set a property for all links (or nodes) is to select <b>Edit > Group Edit</b> from the Menu Bar, hit <kbd>Enter</kbd> to select the entire network, and then select a property and its new value in the <b>Group Editor</b> dialog that appears.

<p>
Run the model and from the <b>View</b> Menu Bar tab select <b>Chlorine</b> for both the Node and Link map themes. After doing this you will notice that the default concentration intervals shown in the Map Legend are much too high for the conditions being modelled. To correct this, click on the Node Theme Legend icon to launch the Legend Editor. Click on the <ui2>  Interval Scale  </ui2> button to display a form in which you can enter a reasonable range of CL2 values, such as `0` to `1.0` mg/L. Afterwards the legend will be modified to have equal intervals between these values. This process is shown in the figure below and should be repeated for the Link Theme Legend as well.
</p>

<imgl images/legendscale.png> <br>

<p>
You can use the slider control on the <b>View</b> tab of the Menu Bar to display the network map at different points in time. When doing so you will notice that nodes 5, 6 and 7 see depressed chlorine levels due to being fed low chlorine water from the tank. The time series plot shown below contrasts chlorine levels in node 3 near the reservoir source with node 5 and the tank node 8.
</p>

<imgl images/cl2results.png>

# Other Things to Explore

<p>
We have only touched the surface of of EPANET-UI's capabilities. Some additional features of the program that you can explore are:
</p>

- editing a property for a group of objects that lie within a user-defined area 

- using Control statements to base pump operation on time of day or tank water levels 

- exploring different Map Options, such as making node size be related to value 

- attaching a basemap image (such as a street map) to the network map 

- creating reports for system energy balance, pumping utilization, pressure variablity, hydraulic profile, and fire flow analysis

- adding calibration data to a project and viewing a calibration report 

- copying the map, a graph, or a report to the clipboard or to a file.

The EPANET-UI Manual describes how to implement these and many more features. 


