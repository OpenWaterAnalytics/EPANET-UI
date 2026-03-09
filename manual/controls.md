# Using Controls
Controls are statements that determine how the network is operated over time. They specify the status of selected links as a function of time, tank water levels, and pressures at select points within the network.

A control action can be either a status condition (`OPEN` or `CLOSED`) or a numerical setting. These affect different types of links in the following ways:
- Control actions for pipes without a check valve (CV) can set a pipe's status to either `OPEN` or `CLOSED`. Pipe's with CV's cannot have controls applied to them.
- Pumps can have their status set to either `CLOSED` (i.e., offline) or `OPEN`. In the latter case the pump's relative speed setting becomes 1.0. If instead the control provides a numerical setting then it is interpreted as the pump's relative speed setting and, if greater than 0, will bring it back on line if it was previously closed.
- If a valve's status is set to `OPEN` or `CLOSED` then it's normal setting (pressure, flow, percent open, etc.) is ignored and the valve behaves as either completely open or completely closed. If a control provides a numerical setting for a valve then any previously fixed open or closed status is removed.  

There are two types of controls that can be used:
- Simple Controls
- Rule-Based Controls

## Simple Controls
Simple controls are used to change the status or setting of a single link based on a specific tank water level, junction pressure, time into the simulation or time of day. You specify these controls by expanding the ***Control Actions*** category in the ***Project Explorer*** and then selecting the ***Simple Controls*** sub-category. A <u>[Simple Controls Editor]</u> dialog will appear into which you can enter your controls.

Simple control statements have one of the formats shown below:
```
LINK linkID action IF NODE nodeID ABOVE/BELOW value
LINK linkID action AT TIME time
LINK linkID action AT CLOCKTIME clocktime
```
where
- `linkID` = a link ID label
- `action` = OPEN, CLOSED, a pump speed setting, or a control valve setting
- `nodeID` = a node ID label
- `value` = pressure for a junction or water level for a tank
- `time` = time since the start of the simulation in decimal hours or in hours:minutes format
- `clocktime` = a 24-hour clock time (hours:minutes).

WARNING:
Using a pair of pressure controls to open and close a link can cause the system to become unstable if the pressure settings are too close to one another. In this case using a pair of Rule-Based controls might provide more stability.

## Rule-Based Controls
Rule-based controls can modify the status or setting of multiple links based on some combination of water levels and pressures at different locations and between different ranges of time. These controls are specified by selecting the ***Rule-Based Controls*** sub-category under the ***Control Actions*** category in the ***Project Explorer***. A <u>[Rule-Based Controls Editor]</u> dialog will appear that contains a text box where the rule statements can be entered.

### Examples
The following set of rules shuts down a pump and opens a by-pass pipe when the level in a tank exceeds a certain value and does the opposite when the level is below another value.
```
RULE 1
IF TANK 1 LEVEL ABOVE 19.1
THEN PUMP 335 STATUS IS CLOSED
AND PIPE 330 STATUS IS OPEN
  
RULE 2
IF TANK 1 LEVEL BELOW 17.1
THEN PUMP 335 STATUS IS OPEN
AND PIPE 330 STATUS IS CLOSED
```

These rules change the tank level at which a pump turns on depending on the time of day.
```
RULE 3
IF SYSTEM CLOCKTIME >= 8 AM
AND SYSTEM CLOCKTIME < 6 PM
AND TANK 1 LEVEL BELOW 12
THEN PUMP 335 STATUS IS OPEN
  
RULE 4
IF SYSTEM CLOCKTIME >= 6 PM
OR SYSTEM CLOCKTIME < 8 AM
AND TANK 1 LEVEL BELOW 14
THEN PUMP 335 STATUS IS OPEN
```

In an extended period simulation, rules are evaluated over a fixed time step that is some fraction of the hydraulic time step. These time steps are supplied with the simulation's <u>[Time Options]</u>. For example, consider what happens with `Rule 3` above after an initial hydraulic solution is found at time 0 and the rule time step is 6 minutes. The system clock would be advanced in 6 minute increments with the water level in `Tank 1` being updated based on what flow rate it sees at the current solution. After each time increment the rule's conditions are checked to see if they are satisfied. If they are, then the status of `Pump 335` is changed and a new hydraulic analysis is made at that point in time.

### Rule Format
Each rule is a series of statements of the form:
```
RULE ruleID
IF condition_1
AND condition_2
OR condition_3
AND condition_4
etc.
THEN action_1
AND action_2
etc.
ELSE action_3
AND action_4
etc.
PRIORITY value
```
where:
- `ruleID` = an ID label assigned to the rule
- `conditon_n` = a condition clause
- `action_n` = an action clause
- `Priority` = a priority value (e.g., a number from 1 to 5).

Only the `RULE`, `IF` and `THEN` portions of a rule are required; the other portions are optional. ***Each rule clause must appear on a separate line.***

When mixing `AND` and `OR` clauses, the `OR` operator has higher precedence than `AND`, i.e.,
```
IF A or B and C
```
is equivalent to
```
IF (A or B) and C.
```
If the interpretation was meant to be
```
IF A or (B and C)
```
then this can be expressed using two rules as in
```
IF A THEN ...
IF B and C THEN ...
```

The `PRIORITY` value is used to determine which rule applies when two or more rules require that conflicting actions be taken on a link. A rule without a priority value always has a lower priority than one with a value. For two rules with the same priority value, the rule that appears first is given the higher priority.

### Condition Clause Format
A condition clause in a Rule-Based Control takes the form of:
```
object id attribute relation value
```
where:
- `object` = a category of network object
- `id` = the object's ID label
- `attribute` = an attribute or property of the object
- `relation` = a relational operator
- `value` = an attribute value.

The Object keyword can be any of the following:
```
NODE  LINK  SYSTEM  JUNCTION  PIPE  RESERVOIR  PUMP  TANK  VALVE
```
When `SYSTEM` is used in a condition no `ID` is supplied.

The following attributes can be used with Node-type objects:
- `DEMAND`
- `HEAD`
- `PRESSURE`.

The following attributes can be used with Tanks:
- `LEVEL`
- `FILLTIME` (hours needed to fill a tank)
- `DRAINTIME` (hours needed to empty a tank).

These attributes can be used with Link-Type objects:
- `FLOW`
- `STATUS` (OPEN, CLOSED, or ACTIVE)
- `SETTING` (pump speed or valve setting).

The `SYSTEM` object can use the following attributes:
- `DEMAND` (total system demand) 
- `TIME` (hours from the start of the simulation expressed either as a decimal number or in hours:minutes format)
- `CLOCKTIME` (24-hour military clock time).

Relation operators consist of the following:
```
=  IS  <>  NOT  <  BELOW  >  ABOVE  <=   >=
```

### Action Clause Format
An action clause in a Rule-Based Control takes the form of:
```
object id STATUS/SETTING IS value
```
where
- `object` = LINK, PIPE, PUMP, or VALVE keyword
- `id` = the object's ID label
- `value` = a status condition (OPEN or CLOSED), pump speed setting, or valve setting.
