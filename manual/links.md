## Pipe Properties

|                   |                                                                   |
|-------------------|-------------------------------------------------------------------|
| Pipe ID           | A unique label used to identify the pipe. It can consist of a combination of up to 31 numerals or characters. It cannot be the same as the ID for any other link.|
| Start Node        | The ID of the node where the pipe begins.|
| End Node          | The ID of the node where the pipe ends.|
| Description       | An optional text string that describes other significant information about the pipe.|
| Tag               | An optional text string (with no spaces) used to assign the pipe to a category, perhaps one based on age or material.|
| Length            | The actual length of the pipe (in feet or meters).|
| Diameter          | The pipe's diameter (in inches or millimeters).|
| Roughness         | The roughness coefficient of the pipe. It is unitless for Hazen-Williams or Chezy-Manning roughness and has units of millifeet (or millimeters) for Darcy-Weisbach roughness.|
| Loss Coefficient  | Unitless minor loss coefficient associated with bends, fittings, etc.|
| Initial Status    | Determines whether the pipe is initially open, closed, or contains a check valve. If a check valve is specified then any flow in the pipe must be from the Start node to the End node.|
| Bulk Coefficient  | The bulk reaction coefficient for the pipe. Use a positive value for growth and a negative value for decay. Time units are 1/days.|
| Wall Coefficient  | The wall reaction coefficient for the pipe. Use a positive value for growth and a negative value for decay. Time units are 1/days.|
| Leak Area         | The average area of a leak opening in square millimeters times the number of leaks per 100 units of pipe length.|
| Leak Expansion    | The rate of leak expansion in square millimeters per unit of pressure head (ft or m) times the number of leaks per 100 units of pipe length. Typical values per leak for plastic pipe are between 0.1 and 0.001 and would be 0 for rigid iron pipe.|

## Pump Properties

|                   |                                                                   |
|-------------------|-------------------------------------------------------------------|
| Pump ID           | A unique label used to identify the pump. It can consist of a combination of up to 31 numerals or characters. It cannot be the same as the ID for any other link.|
| Start Node        | The ID of the node on the suction side of the pump.|
| End Node          | The ID of the node on the discharge side of the pump.|
| Description       | An optional text string that describes other significant information about the pump.|
| Tag               | An optional text string (with no spaces) used to assign the pump to a category, perhaps one based on age, size or location.|
| Pump Curve        | Click the <imgt images/Ellipsis.png> button to select a data curve used to describe the relationship between the head delivered by the pump and the flow through it . If the pump will be a constant energy pump (see below) then it's not necessary to define a pump curve.|
| Power             | The power supplied by the pump in horsepower (kw). It assumes that the pump supplies the same amount of energy no matter what the flow is. This value is ignored if a pump curve is assigned.|
| Speed             | The relative speed setting of the pump (unitless). For example, a speed setting of 1.2 implies that the rotational speed of the pump is 20% higher than the normal setting.|
| Speed Pattern     | Click the <imgt images/Ellipsis.png> button to select a time pattern used to control the pump's operation. The multipliers of the pattern represent the pump's speed settings. A multiplier of zero implies that the pump will be shut off during the corresponding time period.|
| Initial Status    | The initial state of the pump (OPEN for online, CLOSED for offline) at the start of the simulation period. |
| Efficiency Curve  | Click the <imgt images/Ellipsis.png> button to select a data curve that represents the pump's wire-to-water efficiency (in percent) as a function of flow rate. This information is used only to compute energy usage. If no curve is supplied then the global pump efficiency supplied with the project's Energy Options will be used.|
| Energy Price      | The average or nominal price of energy in monetary units per kw-hr. Used only for computing the cost of energy usage. If set to 0 then the global value supplied with the project's Energy Options will be used.|
| Price Pattern     | Click the <imgt images/Ellipsis.png> button to select a time pattern used to describe the variation in energy price throughout the day. Each multiplier in the pattern is applied to the pump's Energy Price to determine a time-of-day pricing for the corresponding period. If no pattern is selected then the global pricing pattern specified in the project's Energy Options will be used.|

## Valve Properties

|                   |                                                                   |
|-------------------|-------------------------------------------------------------------|
| Valve ID          | A unique label used to identify the valve. It can consist of a combination of up to 31 numerals or characters. It cannot be the same as the ID for any other link.|
| Start Node        | The ID of the node on the nominal upstream or inflow side of the valve. (PRVs and PSVs maintain flow in only a single direction.)|
| End Node          | The ID of the node on the nominal downstream or discharge side of the valve.|
| Description       | An optional text string that describes other significant information about the valve.|
| Tag               | An optional text string (with no spaces) used to assign the valve to a category, perhaps one based on type or location.|
| Diameter          | The valve's diameter (in inches or millimeters).|
| Type              | The valve type:
<ul>
<li>**PRV** (Pressure Reducing Valve) - limits the pessure at a point in the pipe network</li>
<li>**PSV** (Pressure Sustaining Valve) - maintains a set pressure at a point in the pipe network</li>
<li>**PBV** (Pressure Breaker Valve) - forces a specified pressure loss to occur across the valve</li>
<li>**FCV** (Flow Control Valve) - limits the flow through the valve to a specified amount</li>
<li>**TCV** (Throttle Control Valve) - simulates a partially closed valve by adjusting the minor head loss coefficient of the valve.</li>
<li>**GPV** (General Purpose Valve) - the user supplies a special flow - head loss relationship for the valve</li>
<li>**PCV** (Positional Control Valve) - a valve whose head loss coefficient is a user-supplied function of its percent open setting.</li>
</ul>|
| Setting           | The valve's operational setting:
<ul>
<li>PRV - pressure (in pressure units)</li>
<li>PSV - pressure (in pressure units)</li>
<li>PBV - pressure (in pressure units)</li>
<li>FCV - flow (in flow units)</li>
<li>PCV - percent open</li>
</ul>|
| Loss Coefficient  | The minor loss coefficient for a completely open valve (unitless).|
| PCV Curve         | Click the <imgt images/Ellipsis.png> button to select a data curve that relates the loss coefficient for a PCV to its percent open setting.|
| GPV Curve         | Click the <imgt images/Ellipsis.png> button to select a data curve that relates the head loss across a GPV to the flow rate.|
| Fixed Status      | The valve's status at the start of the simulation. If set to OPEN or CLOSED then the control setting of the valve is ignored and the valve behaves as an open or closed link, respectively. If set to NONE, then the valve will behave according to its setting.|

NOTE:
A valve's fixed status and its setting can be made to vary throughout a simulation by the use of control statements. If a valve's status was fixed to OPEN/CLOSED, then it can be made active again using a control that assigns a new numerical setting to it.
