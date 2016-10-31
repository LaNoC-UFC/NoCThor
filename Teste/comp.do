exit -sim
vlib work
vmap work work

proc comp_vhdl {vhdl_source} {
    vcom -work work -93 -explicit -bindAtCompile -check_synthesis -fsmverbose w\
    -lint -noDeferSubpgmCheck -nologo -pedanticerrors\
    -quiet -rangecheck $vhdl_source
}

proc comp_sc {sc_source} {
    sccom -g -explicit -incr $sc_source
}

set source_files {
    NoC/Thor_package.vhd
    NoC/Table_package.vhd
    NoC/Thor_RM.vhd
    NoC/fifo_buffer.vhd
    NoC/Thor_buffer.vhd
    NoC/outputArbiter.vhd
    NoC/inputArbiter.vhd
    NoC/Thor_switchcontrol.vhd
    NoC/Thor_crossbar.vhd
    NoC/RouterCC.vhd
    NoC/NOC.vhd
}

foreach file $source_files {
    comp_vhdl $file
}

# SystemC's stuff
comp_sc Monitores/SC_inmod.cpp
comp_sc Monitores/SC_outmod.cpp
sccom -link

# TestBench
comp_vhdl topNoC.vhd
