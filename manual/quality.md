# Modeling Water Quality
The EPANET engine can model the propagation and fate of chemical and biological constituents throughout a distribution system over time. It can also compute water age and perform source tracing.

NOTE:
A model must be run as an extended period simulation (EPS) with duration greater than 0 for a water quality analysis to be made.

## Single Species Analysis
EPANET's single species water quality option can be used to model:
- blending water from different sources
- age of water throughout a system
- loss of chlorine residuals
- growth of disinfection by-products
- propagation of a contaminant intrusion.

Follow these steps to build a single-species water quality model with EPANET-UI:
1. Expand the ***Analysis Options*** topic in the Project Explorer and select its  ***Quality*** sub-option.
2. Select the ***Single Species*** row in the Property Editor and press <kbd>Enter</kbd> to bring up the <u>[Single Species Quality]</u> Editor.
3. Enter your modeling choices in the editor.
4. If modeling a reactive species, specify bulk and pipe wall reaction coeffciients for each pipe. The ***Group Edit*** button on the ***Edit*** Menu Bar makes it easy to set global values all at once.
5. Assign initial water quality concentrations to each node. The ***Group Edit*** feature will also prove useful for this.

Any water entering the network from a Reservoir node will have the node's assigned initial concentration for all time periods unless the node was also assigned a water quality source (see <u>[Water Quality Sources]</u>).  

## Multi-Species Analysis
An extension to the original EPANET solver allows it to analyze multiple interacting chemcial and biological species within the distribution system. Examples include:
- effect of source blending on chemical reaction rates
- chloramine decomposition to ammonia 
- bacterial growth with chlorine inhibition
- oxidation and adsorption of arsenic
- effect of longitudinal dispersion.

To build a multi-species water quality model with EPANET-UI:
1. Expand the ***Analysis Options*** topic in the Project Explorer and select its  ***Quality*** sub-option.
2. Select the ***Multi-Species*** row in the Property Editor and press <kbd>Enter</kbd> to bring up the <u>[Multi-Species Quality]</u> Editor.
3. Enter your modeling choices in the editor.
Please consult the <a https://epanetmsx2manual.readthedocs.io/en/latest/1_introduction.html>EPANET-MSX Manual</a> for a more detailed description of how to build an EPANET multi-species water quality model.

## Water Quality Sources
Both single and multi-species quality models allow you to specify an external source of water quality entering the network at a specific node. The source can be characterized by either a concentration (e.g., mg/L) or a mass flow rate (e.g., mg/minute). For single species analysis you would click the <imgt images/Ellipsis.png> button in the node's Source Quality property to edit its characteristics. For multi-species analysis you would select the ***Sources*** page in the <u>[Multi-Species Quality]</u> Editor to assign sources to specific nodes.

NOTE:
For single species modeling of source tracing, a source is automatically placed at the designated source node and any other sources are ignored.

<p>
***Concentration Sources***<br>
A `CONCENTRATION` source represents the concentration of any external inflow entering a node.
- It applies only when the node has a net negative demand (water enters the network at the node).
- It is best used for nodes that represent source water supplies or treatment works (e.g., reservoirs or nodes assigned a negative demand)
- It should not be used at storage tanks with simultaneous infow/outfow.
</p>

<p>
***Booster Sources***<br>
A boster source represents a substance injected directly into the network irregardless of what the demand is at a node. The following types of booster sources can be specified:
- A `MASS` booster adds a fixed mass flow to whatever mass inflow a node receives from its connecting links.
- A `FLOW PACED` booster adds a fixed concentration to the resultant inflow concentration a node receives from its connecting links.
- A `SET POINT` booster fixes the concentration of any flow leaving the node (as long as the concentration resulting from the inflows is below the setpoint).
Booster sources are best used to model direct injection of a tracer or disinfectant into the network or to model a contaminant intrusion.
</p>

## Tank Mixing
A storage tank's ***Mixing Model*** property determines how its inflow mixes with its current contents.

<p>
***Complete Mixing***<br>
<imgl images/CompleteMix.png>
This mixing  model assumes that all water that enters a tank is instantaneously and completely mixed with the water already in the tank. It is the simplest form of mixing behavior to assume, requires no extra parameters to describe it, and seems to apply quite well to a large number of facilities that operate in fill-and-draw fashion.
</p>

<p>
***Two-Compartment Mixing***<br>
<imgl images/2CompMix.png>
This mixing model divides the available storage volume in a tank into two compartments, both of which are assumed to be completely mixed. The inlet/outlet pipes of the tank are assumed to be located in the first compartment. New water that enters the tank mixes with the water in the first compartment. If this compartment is full, then it sends its overflow to the second compartment where it completely mixes with the water already stored there.
</p>

 <p>
 When water leaves the tank, it exits from the first compartment, which if full, receives an equivalent amount of water from the second compartment to make up the difference. The first compartment is capable of simulating short circuiting between inflow and outflow while the second compartment can represent dead zones. The user must supply a single parameter which is the fraction of the total tank volume devoted to the first compartment.
 </p>
 
 <p>
***First In - First Out (FIFO) Plug Flow Mixing***<br>
<imgl images/FIFOmix.png>
This mixing model assumes that there is no mixing of water at all during its residence time in a tank. Water parcels move through the tank in a segregated fashion where the first parcel to enter is also the first to leave. Physically speaking, this model is most appropriate for baffled tanks that operate with simultaneous inflow and outflow. There are no additional parameters needed to describe this mixing model.</p>

<p>
***Last In - First Out (LIFO) Plug Flow Mixing***<br>
<imgl images/LIFOmix.png>
This mixing model assumes that there is no mixing between parcels of water that enter a tank. However in contrast to FIFO Plug Flow, the water parcels stack up one on top of another, where water enters and leaves the tank on the bottom. Physically speaking this type of model might apply to a tall, narrow standpipe with an inlet/outlet pipe at the bottom and a low momentum inflow. It requires no additional parameters be provided.
</p>
 