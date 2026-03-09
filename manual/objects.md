# Working with Objects
This topic describes the actions that can be applied to visual network objects (nodes, links, and labels) that appear on the Network Map:

## Adding an Object
To add a new object to the network select ***Project > Add*** from the Menu Bar. Then select the type of object you wish to add from the drop-down menu that appears.

HINT:
When starting a new project whose Network Map will contain a basemap backdrop, it is better to add the basemap first before adding objects to to the project. See the <u>[Using a Basemap]</u> topic.

For node objects (Junctions, Reservoirs, or Tanks):
- Left-click the mouse at the location on the Network Map where you want the new node to appear.
- Continue to add more nodes in this fashion until you right-click the mouse or hit <kbd>Esc</kbd>.

For link objects (Pipes, Pumps, or Valves):
- Left-click the mouse on the node where the link begins.
- Then left-click on the node where the link ends. You can left-click at intermediate locations to add curvature to the link.
- Continue to add more links in this fashion until you right-click the mouse or hit <kbd>Esc</kbd>.

For map labels:
- Left-click the mouse at the Network Map location where the upper-left corner of the label should begin.
- Type the label's text into the box that appears and hit <kbd>Enter</kbd>.
- Continue to add more labels in this fashion until you right-click the mouse or hit <kbd>Esc</kbd>.

## Selecting an Object
- Left-click the mouse over the object on the Network Map to select it and have its properties appear in the ***Property Editor***.
- Once a node, link or label is selected you can use the arrow buttons at the top of the ***Property Editor*** to select the previous or next node, link, or label.
- You can also select ***Project > Locate*** from the Menu Bar to make an ***Object Locator*** panel appear above the Map Legend from which you can enter the ID name of a node or link to be selected.

## Moving an Object
Select the node or map label to be moved. Then with the <kbd>Ctrl</kbd> key and left mouse button pressed move the mouse to object's new position. You can also use the <kbd>Ctrl</kbd> plus arrow keys to move the object with more precision.

## Deleting an Object
Select the object to be deleted and then select ***Project > Delete*** from the Menu Bar. Or you can right-click on the object and select ***Delete*** from the popup menu that appears.

## Editing an Object
To edit the properties of an object:
- Select the object to be edited.
- Use the ***Property Editor*** in the lower half of the ***Project Explorer*** to edit its properties.
- Editor fields that contain a <imgt images/Ellipsis.png> button will launch a special customized editor form when clicked on or when <kbd>Enter</kbd> is pressed.

NOTE:
To edit non-visual elements, such as Analysis Options and Control Actions, you would select their category from the ***Project Explorer***.

## Editing a Group of Objects
To edit a property for a group of objects first select ***Edit > Group Edit*** from the Menu Bar. Follow the instructions that appear above the Map Legend to draw a polygon that contains the objects to be edited. A dialog form will then appear in which you can select the category of object to edit, the property to edit and the new value that all objects of that category within the polygon will be assigned.

## Deleting a Group of Objects
To delete a group of objects, select ***Edit > Group Delete*** from the Menu Bar and follow the instructions that appear above the Map Legend to draw a polygon that contains the objects to be deleted.

## Copying and Pasting Objects
The properties of an object can be copied and pasted into another object of the same type. To do so:
1. First select the object whose properties are to be copied.
2. Select ***Edit > Copy*** from the Menu Bar (or right-click on the object and select ***Copy*** from the popup menu that appears).
3. Select an object of the same type whose properties are to be replaced.
4. Select ***Edit > Paste*** from the Menu Bar (or select ***Paste*** from the popup menu that appears when the object is right-clicked on) to replace its properties.

## Reversing a Link
To reverse the direction of a link, first select the link and then select ***Edit > Reverse Link*** from the Menu Bar. Or you can right-click on the link and select ***Reverse*** from the popup menu that appears.

## Reshaping a Link
To reshape a link, first select the link and then select ***Edit > Reshape Link*** from the Menu Bar. A set of instructions will appear in a panel above the Map Legend telling you how to proceed. Alternatively you can right-click on the link and select ***Reshape*** from the popup menu that appears.

NOTE:
The EPANET-UI workspace will remain disabled and you will not be able to pan or zoom the map while a link is being reshaped.

## Converting a Link
Links can be converted from one type to another (such as converting a pipe to a valve). To do so, first select the link to be converted, next select ***Edit > Convert*** from the Menu Bar, and then select the type of link to convert to from the dropdown menu that appears. The converted link will have its properties set to the project's default values so it may need to be edited. You can also convert a link by right-clicking on it and selecting ***Convert to*** from the popup menu that appears.
