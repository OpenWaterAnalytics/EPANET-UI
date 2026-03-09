# Frequently Asked Questions

## General

<details>
<summary>
<i>How can I import a pipe network created with a CAD or GIS program?</i>
</summary>
<br>
See <u>[Importing Data]</u>
</details>
<br>
<details>
<summary>
<i>Can I run multiple EPANET-UI sessions at the same time?</i>
</summary>
<br>
Yes. This could prove useful in making side-by-side comparisons of two or more different design or operating scenarios.
</details>
<br>
<details>
<summary>
<i>How can I create a report of my analysis that can be printed or saved as a PDF file?</i>
</summary>
<br>
While EPANET-UI is running, create a new document in a word processing program, such as MS Word or LibreOffice Writer, and paste into it items like the network map and analysis results that were copied to the clipboard. Later on you can reformat the document and add additional text as needed, and then save or print it.
</details>

## Hydraulics

<details>
<summary>
<i>How do I model a groundwater pumping well?</i>
</summary>
<br>
<p>Represent the well as a reservoir whose head equals the piezometric head of the groundwater aquifer. Then connect your pump from the reservoir to the rest of the network. You can add piping ahead of the pump to represent local losses around the pump.</p>
<p>If you know the rate at which the well is pumping then an alternate approach is to replace the well – pump combination with a junction assigned a negative demand equal to the pumping rate. A time pattern can also be assigned to the demand if the pumping rate varies over time.</p>
</details>
<br>
<details>
<summary>
<i>How do I size a pump to meet a specifc flow?</i>
</summary>
<br>
Set the status of the pump to CLOSED. At the suction (inlet) node of the pump add a demand equal to the required pump flow and place a negative demand of the same magnitude at the discharge node. After analyzing the network, the difference in heads between the two nodes is what the pump needs to deliver.
</details>
<br>
<details>
<summary>
<i>How do I size a pump to meet a specifc head?</i>
</summary>
<br>
Replace the pump with a Pressure Breaker Valve oriented in the opposite direction. Convert the design head to an equivalent pressure and use this as the setting for the valve. After running the analysis the flow through the valve becomes the pump’s design flow.
</details>
<br>
<details>
<summary>
<i>How can I enforce a specifc schedule of source flows into the network from my reservoirs?</i>
</summary>
<br>
Replace the reservoirs with junctions that have negative demands equal to the schedule of source flows. Make sure there is at least one tank or remaining reservoir in the network, otherwise EPANET will issue an error message. You might also need to allow tanks to overflow to avoid a condition where total source flow exceeds total demand and all tanks are full.
</details>
<br>
<details>
<summary>
<i>How can I analyze fire flow conditions for a particular junction node?</i>
</summary>
<br>
<p>To determine the maximum pressure available at a node when the flow demanded must be increased to suppress a fire, add the fire flow to the node’s normal demand, run the analysis, and note the resulting pressure at the node.</p>
<p>To determine the maximum flow available at a particular pressure, set the emitter coeffcient at the node to a large value (e.g., 100 times the maximum expected flow) and add the required pressure head (2.3 times the pressure in psi) to the node’s elevation. After running the analysis, the available fire flow equals the emitter demand reported for the node. (If the reported pressure is not close to 0 then increase the emitter coefficient.)</p>
</details>
<br>
<details>
<summary>
<i>How do I model a reduced pressure backfow prevention valve?</i>
</summary>
<br>
Use a General Purpose Valve with a headloss curve that shows increasing head loss with decreasing flow. Information from the valve manufacturer should provide help in constructing the curve. Place a check valve (i.e., a short length of pipe whose status is set to CV) in series with the valve to restrict the direction of flow.
</details>
<br>
<details>
<summary>
<i>How do I model a pressurized pneumatic tank?</i>
</summary>
<br>
<p>If the pressure variation in the tank is negligible, use a very short, very wide cylindrical tank whose elevation is set close to the pressure head rating of the tank. Select the tank dimensions so that changes in volume produce only very small changes in water surface elevation.</p>
<p>If the pressure head developed in the tank ranges between 𝐱 and 𝐲, with corresponding volumes 𝐠1 and 𝐠2, then use a cylindrical tank whose cross-sectional area equals (𝐠2 − 𝐠1)/(𝐲 − 𝐱).</p>
</details>
<br>
<details>
<summary>
<i>How do I model a tank inlet that discharges above the water surface?</i>
</summary>
<br>
<p>Use the confguration shown below:</p>
<imgl images/TankInlet.png>  
<p>The tank’s inlet consists of a Pressure Sustaining Valve followed by a short length of large diameter pipe. The pressure setting of the PSV should be 0, and the elevation of its end nodes should equal the elevation at which the true pipe connects to the tank. Use a Check Valve on the tank’s outlet line to prevent reverse flow through it.</p>
</details>

## Water Quality

<details>
<summary>
<i>How do I determine initial conditions for a water quality analysis?</i>
</summary>
<br>
<p>If simulating existing conditions monitored as part of a calibration study, assign measured values to the nodes where measurements were made and interpolate (by eye) to assign values to other locations. It is highly recommended that storage tanks and source locations be included in the set of locations where measurements are made.</p>
<p>To simulate future conditions start with arbitrary initial values (except at the tanks) and run the analysis for a number of repeating demand pattern cycles so that the water quality results begin to repeat in a periodic fashion as well. The number of such cycles can be reduced if good initial estimates are made for the water quality in the tanks. For example, when modeling water age a tank's initial value (in hours) could be set to 24 divided by the fraction of its volume it exchanges each day.</p>
</details>
<br>
<details>
<summary>
<i>How do I estimate values of the bulk and wall reaction coeffcients?</i>
</summary>
<br>
Bulk reaction coeffcients can be estimated by performing a bottle test in the laboratory. Wall reaction rates cannot be measured directly. They must be back-fitted against calibration data collected from field studies (e.g., using trial and error to determine coeffcient values that produce simulation results that best match feld observations). Plastic pipe and relatively new lined iron pipe are not expected to exert any signifcant wall demand for disinfectants such as chlorine and chloramines.
</details>
<br>
<details>
<summary>
<i>How can I model a chlorine booster station?</i>
</summary>
<br>
Place the booster station at a junction node with zero or positive demand or at a tank. Select the node into the Property Editor and click the ellipsis button in the <i>Source Quality</i> field to launch the <u>[Source Quality]</u> editor. In the editor, set <i>Source Type</i> to SETPOINT BOOSTER and set <i>Source Quality</i> to the chlorine concentration that water leaving the node will be boosted to. Alternatively, if the booster station will use flow-paced addition of chlorine then set <i>Source Type</i> to FLOW PACED BOOSTER and <i>Source Quality</i> to the concentration that will be added to the concentration leaving the node. Specify a time pattern ID in the <i>Time Pattern</i> field if you wish to vary the boosting level with time.
</details>
<br>
<details>
<summary>
<i>How would I model trihalomethane (THM) growth in a network?</i>
</summary>
<br>
THM growth can be modeled using frst-order saturation kinetics. Set the bulk reaction order to 1 and the limiting concentration to the maximum THM level that the water can produce,given a long enough holding time. Set the bulk reaction coeffcient to a positive number reflective of the rate of THM production (e.g., 0.7 divided by the THM doubling time). Estimates of the reaction coeffcient and the limiting concentration can be obtained from laboratory testing. The reaction coeffcient will increase with increasing water temperature. Initial concentrations at all network nodes should at least equal the THM concentration entering the network from its source node.
</details>
<br>
<details>
<summary>
<i>How can I model longitudinal dispersion of a water quality constituent?</i>
</summary>
<br>
Use the EPANET Multi-Species Extension (MSX) option to model dispersion, even if you are only tracking a single species.
