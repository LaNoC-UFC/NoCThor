exit -sim
vlib work
vmap work work

# Packages
vcom -work work -93 -explicit NoC/Hermes_package.vhd
#vcom -work work -93 -explicit Hamming/HammingPack16.vhd

# Hamming and fault blocks
#vcom -work work -93 -explicit Hamming/Encoder.vhd
#vcom -work work -93 -explicit Hamming/Decoder.vhd
#vcom -work work -93 -explicit Hamming/fault_in.vhd

# FPPM block
#vcom -work work -93 -explicit FPPM/FPPM_AA00.vhd

# NoC
vcom -work work -93 -explicit NoC/Table_package.vhd
#vcom -work work -93 -explicit NoC/Hermes_table.vhd
vcom -work work -93 -explicit NoC/Hermes_RM.vhd
vcom -work work -93 -explicit NoC/Hermes_buffer.vhd
vcom -work work -93 -explicit NoC/FaultDetection.vhd
vcom -work work -93 -explicit NoC/Hermes_switchcontrol.vhd
vcom -work work -93 -explicit NoC/Hermes_crossbar.vhd
vcom -work work -93 -explicit NoC/RouterCC.vhd

# SystemC's stuff
sccom -work work -g -explicit Monitores/SC_inmod.cpp
sccom -work work -g -explicit Monitores/SC_outmod.cpp
#sccom -work work -g -explicit Monitores/SC_failmod.cpp
sccom -link

# TestBench
vcom -work work -93 -explicit NoC/NOC.vhd
vcom -work work -93 -explicit topNoC.vhd

#quit -f