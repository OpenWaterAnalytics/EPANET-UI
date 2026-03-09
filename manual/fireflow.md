# Fire Flow Analysis
Selecting <b>Project > Report > Fire Flow Report</b> from the Menu Bar will have EPANET-UI perform a fire flow analysis for a designated group of nodes. For each such node, the analysis will determine:
1. The pressure that results when a stipulated target fire flow is added to the node's normal demand.
2. The largest fire flow demand at the node that will maintain pressures above a stipulated target.
This kind of information is used to insure that a distribution system is capable of providing enough water to meet fire fighting requirements.

NOTE:
The EPANET-UI workspace will remain disabled while a File Flow Report is being setup, generated, and viewed.

## Setup

When a Fire Flow Report is selected, a Fire Flow Selector panel will appear above the Map Legend. It contains several pages in which you set up how the fire flow analysis should be performed:

- The first page lets you specify
  - the target fire flow value to use,
  - the target pressure to be maintained,
  - for extended period analyses, the time of day to analyze.

- The second page presents options for selecting network nodes to be analyzed:
  - include individual nodes selected from the network map
  - include all nodes with a specific Tag property
  - include all nodes that lie within a designated polygon region of the network map
  - include all network nodes.

- The third page lists the nodes selected for analysis.
  - Nodes can be added by clicking their location on the network map or removed using the page's <kbd>Remove</kbd> button.
  - If nodes were to be added by region, instructions will appear on how to select the region (in the same manner used for <u>[Editing a Group of Objects]</u>).
  - This page will be skipped if all network nodes were selected.

- The fourth page lets you select a zone within which the target pressure for each fire flow node must be met:
  - only at each individual node
  - at all nodes selected for analysis
  - at all nodes in the network.

- The final page summarizes the fire flow selections made and will generate a report when the <kbd>Compute Fire Flows</kbd> button is pressed.

## Analysis

The following steps are performed to find the available fire flow for each node selected for analysis:

- A simulation is run with no fire flow added to establish the static pressure at the node. If that pressure is below the target pressure then the node is assigned an available fire flow of 0.

- Otherwise a second simulation is made with the full fire flow target added to the node's normal demand at the designated time of day. If the target presure is met or exceeded at all nodes in its fire flow zone then the available fire flow is the full target fire flow.

- Otherwise a sequential search procedure (called Ridder's Method) is used to find the largest fire flow at the node that will just meet the target pressure in its fire flow zone.

## Results

The results of a Fire Flow Analysis are displayed in a report window with three tabbed pages:
- The <b>Summary</b> page summarizes the analysis setup choices and the overall results.
- The <b>Details</b> page contains a table listing results for each node selected for analysis.
- The <b>Map</b> page displays the available fire flow (as a percentage of the target flow) in color-coded fashion on a map of the pipe network.

The figure below gives an example of the table appearing on the Details page of the report. The columns contain the following information:

<imgl images/FireFlowResults.png><br>

|                   |                                                       |
|-------------------|-------------------------------------------------------|
| Node              | the ID name of a node selected for fire flow analysis |
| Static Pressure   | the pressure at the node under no fire flow |
| Target Fire Flow  | the desired fire flow demand at the node |
| Residual Pressure | the node's pressure when subjected to the target fire flow |
| Available Fire Flow | the highest fire flow, at or below the target flow, that can be delivered without pressures falling below the target pressure within the node's fire flow zone |
| Critical Pressure | the lowest pressure within the fire flow zone under the node's available fire flow |
| Critical Node     | the ID name of the node in the fire flow zone with the critical pressure |

The table shown above was generated for a target fire flow of 2000 gpm, a target pressure of 20 psi, and a pressure zone consisting of all selected fire flow nodes. We note the following:
- Node 213 had a pressure of 18 psi under the full target fire flow. To meet the 20 psi target pressure its available flow had to be reduced to 1889 gpm.

- Under the target fire flow, Node 211's pressure was 22 psi. While this exceeds the target pressure, Node 213 had a lower pressure of 21 psi so it became the critical node. Because this also exceeds the target pressure, the full target fire flow could be achieved by Node 211.

- Node 253 had a negative pressure under the target fire flow. It's available fire flow had to be reduced by over half to meet the 20 psi target.

- While Node 255 could meet the pressure target under the full target fire flow, the pressure target could not be met at Node 253. To have the latter node meet the target, the available fire flow at Node 255 had to be reduced down to 1830 gpm.
