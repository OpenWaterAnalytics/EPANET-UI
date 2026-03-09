<h1>Modeling Water Demands</h1>

<h2>Consumer Demands</h2>

Consumer demands represent the water consumption rate for various uses that are assigned to junction nodes throughout the network. They can consist of residential, industrial, commercial and irrigation demands. They can also include non-metered water usage such as losses due to pipe leakage and fire flow demand. One normally starts with specifying nominal or average day demands to which peaking factors (for snapshot analysis) or time pattern factors (for extended period analysis) can be applied. 

<imgr images/demands.png> The figure on the right shows the fields of a junction node's Property Editor where demand information for the node is supplied. The *Base Demand* is normally the nominal or average demand occurring at the node. However it may be assigned some other value such as when simulating a fire flow demand. The Demand Pattern field is used to assign a Time Pattern to the Base Demand (see the <u>[Time Patterns]</u> topic). The *Demand Categories* field is used to assign base demands and patterns to more than one category of demands (see the <u>[Demand Categories]</u> topic).

<p>
<b>Demand Driven Analysis</b> (DDA) requires that the user-supplied demands at each node must be met no matter what pressures may result and is the classical approach to computing pipe network hydraulics. However meeting this condition mathematically may produce pressures that in reality are too low to provide the required demand and may even be negative.
</p>
<p>
<b>Pressure Driven Analysis</b> (PDA) is an alternative to DDA that allows demand to be a function of pressure. Delivered demand is zero when pressure is below a minimum level and is at its full required value when some service pressure is exceeded. In between these levels demand varies as a power function of pressure. 
</p>
<p>
The choice of method to use is made by setting the *Demand Model* attribute of the project's <u>[Demand Options]</u>. If PDA is chosen then one must also set values for the *Minimum Pressure* and *Service Pressure* parameters that determine how demands are influenced by pressure.
</p>

<h2>Emitter Demands</h2>

Emitters are devices associated with junctions that model the flow through a nozzle or orifice. In these situations the demand (i.e. the flow rate through the emitter) varies in proportion to the pressure at the junction raised to some power. The constant of proportionality is termed the "discharge coefficient". For nozzles and sprinkler heads the exponent on pressure is 0.5 and the manufacturer usually states the value of the discharge coefficient as the flow rate in gpm through the device at a 1 psi pressure drop (or lps at 1 meter pressure drop).

Emitters are used to model outflow from sprinkler systems and irrigation networks. They can also be used to simulate leakage in a pipe connected to the junction (if a discharge coeffcient and pressure exponent for the leaking crack or joint can be estimated) or compute a fire flow at the junction (the flow discharged through the hose hookup at a hydrant).

<h2>Leakage Demands</h2>

While emitters can be used to model leakage from pipe cracks and joints, it can be difficult to assign meaningful values to the emitter flow coefficient and the global emitter exponent to be used. Conceptually the flow coefficient should somehow reflect the number of pipes connected to the node and the assumed number of cracks and their areas in each connecting pipe. Regarding the flow exponent, empirical studies have shown that it can also vary with pressure.

The FAVAD (Fixed and Variable Discharge) leakage model uses the following equation to estimate the leakage rate from a crack along a pipe:
<p>
<i>`Leakage Flow = Cd (Ao H^0.5 + m H^1.5)`</i>
</p>
where *Cd* is a discharge coefficient, *Ao* is the area of a crack under zero pressure conditions, *H* is the pressure head it sees, and *m* is rate at which the crack area expands as pressure increases (with experimental values between 0 and 0.001 (sq mm)/m depending on pipe material and crack size).

This model has been incorporated into the EPANET hydraulic solver by assigning individual pipes a total `Leak Area` and total `Leak Expansion` properties. If N represents the number of leaking cracks per 100 units of pipe length then a pipe's `Leak Area` would be N times its average crack area in sq. mm  and its `Leak Expansion` value would be N times the average crack expansion rate in sq. mm per unit of pressure head. Crack area is always expressed in sq. mm regardless of what unit system a project uses. Internally EPANET converts the FAVAD equation into an equivalent set of nodal emitters, one with a pressure exponent of 0.5 and another with exponent of 1.5, whose discharge coefficients reflect the summed leak coefficients of the pipes connected to the node. After a simulation, both the leakage flow from each node and the leakage flow from each pipe are available for viewing.
