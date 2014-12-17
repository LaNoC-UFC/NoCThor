quit -sim
vsim -voptargs="+noassertdebug+O5" work.topnoc
set StdArithNoWarnings 1
#run 200 ms
#quit -sim
#quit -f
