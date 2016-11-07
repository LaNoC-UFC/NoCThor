exit -sim
vlib work
vmap work work

proc comp_vhdl {vhdl_source} {
    vcom -work work -93 -explicit -bindAtCompile -check_synthesis -fsmverbose w\
    -lint -noDeferSubpgmCheck -nologo -pedanticerrors\
    -quiet -rangecheck $vhdl_source
}

set source_files {
    NoC/fifo_buffer.vhd
    tests/fifo_buffer_test.vhd
}

foreach file $source_files {
    comp_vhdl $file
}

vsim -voptargs="+noassertdebug+O5" -onfinish stop work.fifo_buffer_test
run 1 ms
quit -sim
