exit -sim
vlib work
vmap work work

# Packages
vcom -93 -explicit -nocheck -quiet NoC/Hermes_package.vhd
vcom -93 -explicit -nocheck -quiet NoC/Table_package.vhd

# NoC
vcom -93 -explicit -nocheck -quiet NoC/Hermes_RM.vhd
vcom -93 -explicit -nocheck -quiet NoC/Hermes_buffer.vhd
vcom -93 -explicit -nocheck -quiet NoC/Hermes_switchcontrol.vhd
vcom -93 -explicit -nocheck -quiet NoC/Hermes_crossbar.vhd
vcom -93 -explicit -nocheck -quiet NoC/RouterCC.vhd

# SystemC's stuff
sccom -g -explicit -incr Monitores/SC_inmod.cpp
sccom -g -explicit -incr Monitores/SC_outmod.cpp
sccom -link

# TestBench
vcom -93 -explicit -nocheck -quiet NoC/NOC.vhd
vcom -93 -explicit -nocheck -quiet topNoC.vhd

#quit -f
