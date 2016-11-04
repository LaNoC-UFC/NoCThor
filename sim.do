quit -sim
vsim -voptargs="+noassertdebug+O5" -onfinish exit work.topnoc
#vsim -voptargs="+noassertdebug+O5" -onfinish stop work.topnoc
set StdArithNoWarnings 1
file delete npack
run -all

#quit -f
