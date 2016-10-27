Thor Network-on-Chip
====

Thor is a Hermes-based (and improved) NoC implemented in VHDL.  

This repository contains the NoC itself and the input/output modules (in SystemC)
that inject/collect traffic in/from the network.
It also contains TCL scripts to compile and simulate with Modelsim.  

Thor is a highly parameterizable, clean and easy-to-understand implementation.
It's frequently checked for synthesis compliance and is coded in VHDL'93.
## Directory tree
## Parameters/Customization
Thor can be easily customized.
Two files need to be changed in order to accomplish that:
Thor_package.vhd and SC_common.h.
The last one only in the case you change the flit width.  

The parameters are: flit width, input buffers depth and NoC size.  

As Thor uses as routing mechanism tables,
the routing algorithm can also (not so easily) be changed by filling these tables.
All you have to do is follow the RBR codification.
## Simulation
### Input files
### Output files
### TCL Scripts
## Related Resources
