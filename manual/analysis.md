# Running a Simulation
Once a network has been created and its properties set, a hydraulic/water quality simulation can be run. The simulation will determine:
- the hydraulic head, pressure and water quality at each node
- the demand requested and supplied at each junction node
- the flow, velocity, head loss, leakage, and water quality in each pipe
- the flow and head delivered by each pump  
in each time period over which the simulation is made. To run a simulation:
- Specify a set of analysis options (e.g., duration, time steps, demand model, water quality model, convergence criteria, etc.) to be used.
- Click the ***Analyze*** button on the Menu Bar's ***Project*** tab (or click the <imgt images/analyze.png> Speed Bar button).
- Troubleshoot any errors or warnings noted on the run's Status Report.

Afterwards you can view the simulation results in a variety of ways  -- see <u>[Viewing Simulation Results]</u>.

## Analysis Options
The following categories of analysis options can be set by selecting ***Analysis Options*** from the Project Explorer.

### Hydraulic Options
|              |                                                                               |
|--------------|-------------------------------------------------------------------------------|
| Maximum Trials | The maximum number of trials used to solve network hydraulics at each hydraulic time step of a simulation.|
| Accuracy | The principal convergence criterion that determines when a hydraulic solution has been reached. The trials end when the sum of all flow changes from the previous solution divided by the total flow in all links is less than this number.|
| Head Tolerance | Another convergence criterion requiring that the head loss computed by the project's head loss formula compared to the difference in nodal heads across each link be less than the specified value (in ft or m). If set to 0 then this criterion is not used.|
| Flow Tolerance | Another convergence criterion requiring that the largest absolute flow change between the current and previous trial solutions be less than the specified value (in flow units). If set to 0 then this criterion is not used.|
| If Unbalanced | Determines what happens if a hydraulic solution cannot be reached within the maximum number of trials at some time into the simulation:
<ul>
<li>`STOP` will halt the entire analysis at that point.</li>
<li>`CONTINUE` will continue the analysis with a warning message issued.</li>
</ul>|
| Status Reporting | Determines how much detail will appear in the run's status report:
<ul>
<li>`NONE` generates no report (other than for error or warning messages)</li>
<li>`NORMAL` - the report identifies when network components change their status</li>
<li>`FULL` - the report also includes the accuracy criterion at each trial at each time step.</li>
</ul>|
| CHECKFREQ | Sets the number of solution trials that pass before the status of pumps, check valves, flow control valves and pipes connected to tanks are once again updated. For example, a value of 2 means that status checks are made every other trial.|
| MAXCHECK | The number of solution trials after which periodic status checks are discontinued. Instead, a status check is made only after convergence is achieved. For example, a value is 10 means that after 10 trials, instead of checking status every `CHECKFREQ` trials, status is checked only at convergence.|
| DAMPLIMIT | The `ACCURACY` value at which solution damping and status checks on control valves (PRVs and PSVs) should begin. Damping limits all flow changes to 60% of what they would otherwise be as future trials unfold. A value of 0 indicates that no damping should be used and that status checks on control valves are made at every iteration. Setting this limit to 1.0 or 0.1 can sometimes help fix non-converging simulations.|

### Demand Options
|              |                                                                               |
|--------------|-------------------------------------------------------------------------------|
| Demand Model | Specifies whether a demand driven analysis (`DDA`) or a pressure driven analysis (`PDA`) should be made. Under `DDA` full nodal demands are always met even if negative pressures result. `PDA` assumes that demand varies between 0 and its full value as a power function of nodal pressure between some minimum and service level values.|
| Default Pattern | Provides the ID label of a default demand pattern to be applied to all junctions where no demand pattern was specified. If no such pattern exists then by default the pattern consists of a single multiplier equal to 1.0. If left blank then EPANET will try to use a global demand pattern named "1" if it exists. |
| Demand Multiplier | Adjusts the values of baseline demands for all junctions and all demand categories. For example, a value of 2 doubles all baseline demands, while a value of 0.5 would halve them.|
| Service Pressure | The pressure required to supply a node's full demand under a pressure driven analysis. It has no effect on a demand driven analysis (but it is used to compute performance metrics in the <u>[Energy Report]</u>). It must be at least 0.1 psi or m higher than the Minimum Pressure setting.|
| Minimum Pressure | The pressure below which no demand can be delivered under a pressure driven analysis. It has no effect on a demand driven analysis.|
| Pressure Exponent | The power to which pressure is raised when computing the demand delivered to a node under a pressure driven analysis. It has no effect on a demand driven analysis. The recommended value is 0.5. |
| Emitter Exponent | The power to which the pressure at a junction is raised when computing the flow issuing from an emitter. The recommended value  is 0.5.|
| Emitter Can Backflow | `YES` if backflow through an emitter is allowed, `NO` if it is not allowed.|

### Water Quality Options
|              |                                                                               |
|--------------|-------------------------------------------------------------------------------|
| Single Species Model | Clicking the <imgt images/Ellipsis.png> button will bring up EPANET's <u>[Single Species Quality]</u> Editor where you can elect to model:
<ul>
<li>a chemical constituent (such as chlorine)</li>
<li>water age</li>
<li>percent of flow originating from a designated node</li>
<li>no water quality</li>
</ul>
View the <u>[Single Species Quality]</u> Editor topic to see what specific properties need to be provided.|
| Multi-Species Model | Clicking the <imgt images/Ellipsis.png> button will bring up EPANET's Multi-Species Water Quality Editor. It allows you to model several interacting water quality constituents and processes, such as multi-source chlorine decay,  arsenic oxidation with pipe wall adsorption, and bacterial regrowth.|

### Time Options
|              |                                                                               |
|--------------|-------------------------------------------------------------------------------|
| Duration | The full duration of the simulation in hours. Enter 0 for a snapshot analysis.|
| Hydraulic Step | Determines how often a new hydraulic state of the network is computed. If greater than either the Pattern or Report time step it will be automatically reduced. The default is 1 hour for new projects.|
| Quality Step | The time step used to track changes in water quality throughout the network. It normally defaults to 1/10 of the hydraulic time step.|
| Pattern Step | The interval between time periods in all time patterns. The default is 1 hour for new projects.|
| Pattern Start |The time offset at which all patterns will start. For example, a value of 6 hours would start the analysis with each pattern in the time period that corresponds to hour 6. The default is 0 for new projects.|
| Report Step |The time interval between which output results are reported. The default is 1 hour for new projects. |
| Report Start | The length of time into the analysis at which output results begin to be reported. The default is 0 for new projects.|
| Rule Step | The time step used to check for changes in system status due to activation of rule-based controls between hydraulic time steps. The default for new projects is 1/10 of the hydraulic time step.|
| Clock Start | The time of day in military time (e.g., 15:00 for 3:00 PM) at which reporting begins. The default is 0 (12 am midnight) for new projects. |
| Statistic | Determines what kind of statistical post-processing should be done on the time series of simulation results generated.
<ul>
<li>AVERAGED reports a set of time-averaged results</li>
<li>MINIMUM reports only the minimum values</li>
<li>MAXIMUM reports only the maximum values</li>
<li>RANGE reports the difference between the minimum and maximum values</li>
<li>NONE reports the full time series for all quantities for all nodes and links and is the default.</li>
</ul>|

NOTE:
All times should be entered in hours:minutes format with the exception that ***Duration*** can be in decimal hours (e.g., 48.5) and ***Quality Step*** can be in hours:minutes:seconds.

### Energy Options
|              |                                                                               |
|--------------|-------------------------------------------------------------------------------|
| Pump Efficiency | The percent efficiency used for pumps that don't have an efficiency curve assigned to them. For new projects it is 75%. |
| Energy Price / kwh | The average price of electricity used to run pumps per kilowatt hour. Price can be in any currency.|
| Price Pattern | Click the <imgt images/Ellipsis.png> button to select a time pattern that describes how the price of energy changes over time.|
| Demand Charge | The added cost per maximum kilowatt used over the analysis period.|

## Troubleshooting Results

Error and Warning messages will be issued when problems are encountered in running a hydraulic/water quality analysis. These messages will appear in the simulation's ***Status Report*** (select ***Project > Report > Status Report*** to view it).

***Pumps Cannot Deliver Flow or Head***

EPANET will issue a warning message when a pump is asked to operate outside the range of its pump curve. If the pump is required to deliver more head than its shutoff head, EPANET will close the pump down. This might lead to portions of the network becoming disconnected from any source of water.

***Network is Disconnected***

A network is deemed to be disconnected if there is no way to provide water to all nodes that have demands. This can occur if there is no path of open links between a junction with demand and either a reservoir, a tank, or a junction with a negative demand. If the problem is caused by a closed link a hydraulic solution will still be computed (probably with extremely large negative pressures) and the program will attempt to identify the problem link in its Status Report. If no connecting link(s) exist
it will be unable to solve the hydraulic equations for flows and pressures and will return an Error 110 message when an analysis is made. Under an extended period simulation it is possible for nodes to become disconnected as links change status over time.

***Negative Pressures Exist***

A warning message will be issued when negative pressures occur at junctions that have positive demands. This usually indicates that there is some problem with the way the network has been designed or operated. Negative pressures can occur when portions of the network can only receive water through links that have been closed off. In such cases an additional warning message about the network being disconnected is also issued. Switching to a PDA demand model is another way to avoid negative pressure warnings.

***System Unbalanced***

A System Unbalanced condition can occur when the hydraulic solver cannot converge to a solution in some time period within its allowed maximum number of trials. This situation can occur when valves, pumps, or pipelines keep switching their status from one trial to the next as the search for a hydraulic solution proceeds. For example, the pressure limits that control the status of a pump may be set too close together. Or a pump's head curve might be too flat causing it to keep shutting on and off.

To eliminate the unbalanced condition one can try:
- increasing the allowed maximum number of trials
- loosening the convergence accuracy requirement
- setting the DAMPLIMIT hydraulic option to a non-zero value (like 0.1).

Each of these parameters are set with the project’s Hydraulic Options. If the unbalanced condition persists, then another hydraulic option, labeled “If Unbalanced”, offers two ways to handle it. One is to terminate the entire analysis once the condition is encountered. The other is to continue seeking a hydraulic solution for another 10 trials with the status of all links frozen to their current values. If convergence is achieved then a warning message is issued about the system possibly being unstable. If convergence is not achieved then a “System Unbalanced” warning message is issued. In either case, the analysis will proceed to the next time period.

If an analysis in a given time period ends with the system unbalanced then one should recognize that the hydraulic results produced for this time period are inaccurate. Depending on circumstances, such as errors in flows into or out of storage tanks, this might affect the accuracy of results in all future periods as well.

***Hydraulic Equations Unsolvable***

Error 110 is issued if at some point in an analysis the set of equations that model flow and energy balance in the network cannot be solved. This can occur when some portion of a system demands water but has no links physically connecting it to any source of water. In such a case warning messages about
nodes being disconnected are issued. The equations might also be unsolvable if unrealistic numbers were used for certain network properties.
