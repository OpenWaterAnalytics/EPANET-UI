# Object Properties

## Junction Properties

|                   |                                                                   |
|-------------------|-------------------------------------------------------------------|
| Junction ID       | A unique label used to identify the junction. It can consist of a combination of up to 31 numerals or characters. It cannot be the same as the ID for any other node.|
| Description       | An optional text string that describes other significant information about the junction.|
| Tag               | An optional text string (with no spaces) used to assign the junction to a category, such as a pressure zone.|
| Elevation         | The elevation (in feet or meters) above some common reference of the junction.  Elevation is used to determine the pressure at the junction from its computed hydraulic head.|
| Base Demand       | The average or nominal demand for water by the main category of consumer at the junction, as measured in the current flow units. A negative value is used to indicate an external source of flow into the junction.|
| Demand Pattern    | Click the <imgt images/Ellipsis.png> button to select a time pattern used to characterize time variation in demand for the main category of consumer at the junction. The pattern provides multipliers that are applied to the Base Demand to determine actual demand in a given time period.|
| Demand Categories | Click the <imgt images/Ellipsis.png> button to display a Demand Category Editor that allows base demands and time patterns to be assigned to other categories of users at the junction.|
| Emitter Coefficient | Discharge coefficient for an emitter (sprinkler or nozzle) placed at the junction. Units are flow units at 1 unit of pressure drop (psi or m). Set to 0 if no emitter is present.|
| Initial Quality   | Water quality level at the junction at the start of the simulation.|
| Source Quality    | Click the <imgt images/Ellipsis.png> button to display a Source Quality Editor which allows you to specify the quality of any water entering the network at this location.|

## Reservoir Properties

|                   |                                                                   |
|-------------------|-------------------------------------------------------------------|
| Reservoir ID      | A unique label used to identify the reservoir. It can consist of a combination of up to 31 numerals or characters. It cannot be the same as the ID for any other node.|
| Description       | An optional text string that describes other significant information about the reservoir.|
| Tag               | An optional text string (with no spaces) used to assign the reservoir to a category, such as a pressure zone.|
| Elevation         | The elevation (in feet or meters) of water in the reservoir.|
| Elevation Pattern | Click the <imgt images/Ellipsis.png> button to select a time pattern used to model time variation in the reservoir's water elevation. This property is useful if the reservoir represents a tie-in to another system whose pressure varies with time.|
| Initial Quality   | Water quality level at the reservoir at the start of the simulation.|
| Source Quality    | Click the <imgt images/Ellipsis.png> button to display a Source Quality Editor which allows you to specify the quality of any water entering the network at this location.|

## Tank Properties

|                   |                                                                   |
|-------------------|-------------------------------------------------------------------|
| Tank ID           | A unique label used to identify the tank. It can consist of a combination of up to 31 numerals or characters. It cannot be the same as the ID for any other node.|
| Description       | An optional text string that describes other significant information about the tank.|
| Tag               | An optional text string (with no spaces) used to assign the tank to a category, such as a pressure zone.|
| Elevation         | The elevation (in feet or meters) of the tank's bottom (not the ground elevation). |
| Initial Level     | The height (in feet or meters) of the water surface above the bottom elevation of the tank at the start of the simulation.|
| Minimum Level     | The minimum height (in feet or meters) of the water surface above the bottom elevation that will be maintained. The tank will not be allowed to drop below this level.|
| Maximum Level     | The maximum height (in feet or meters) of the water surface above the bottom elevation that will be maintained. The tank will not be allowed to rise above this level.|
| Diameter          | The diameter of the tank (in feet or meters). For cylindrical tanks this is the actual diameter. For square or rectangular tanks it can be an equivalent diameter equal to 1.128 times the square root of the cross-sectional area. For tanks whose geometry will be described by a curve (see below) it can be set to any value.|
| Minimum Volume    | The volume of water in the tank when it is at its minimum level, in cubic feet (cubic meters). This is an optional property, useful mainly for describing the bottom geometry of non-cylindrical tanks where a volume versus depth curve will not be supplied (see below).|
| Volume Curve      | Click the <imgt images/Ellipsis.png> button to select a data curve that describes the relation between tank volume and water level. This property is useful for characterizing irregular-shaped tanks. If no curve is supplied then the tank is assumed to be cylindrical.|
| Can Overflow      | If set to YES then any inflow to a full tank becomes overflow (i.e. spillage). Otherwise any links that would normally send flow to the tank are temporarily closed when the tank becomes full.|
| Mixing Model      | The type of water quality mixing that occurs within the tank. The choices include:
<ul>
<li>fully mixed (**MIXED**)</li>
<li>two compartment mixing (**2COMP**)</li>
<li>first-in first-out plug flow (**FIFO**)</li>
<li>last-in first-out (**LIFO**)</li>
See the <u>[Tank Mixing]</u> section for descriptions of these alternatives.
</ul>|
| Mixing Fraction   | The fraction of the tank's total volume that comprises the inlet-outlet compartment of the two-compartment (**2COMP**) mixing model.|
| Reaction Coefficient | The bulk reaction coefficient for chemical reactions in the tank. Use a positive value for growth reactions and a negative value for decay. Time units are 1/days.|
| Initial Quality   | Water quality level in the tank at the start of the simulation.|
| Source Quality    | Click the <imgt images/Ellipsis.png> button to display a Source Quality Editor in which the quality of water entering the network from the tank can be specified (regardless of the actual quality in the tank).|
