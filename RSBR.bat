@echo off

if -%1-==-- echo Argument one not provided & exit /b
if -%2-==-- echo Argument two not provided & exit /b

set rsbrInp=./%1
set simuInp=%2
set tableVHD=./Teste/NoC/
mkdir Stats

for %%i in (%rsbrInp%/*) do call :for_body %%i
exit /b

:for_body
	echo %1
	ren %simuInp% %1
	set simuInp=%1
	java -jar SBR.jar "%rsbrInp%\%1"
	java -jar RBR.jar "%rsbrInp%\%1" nmerge 1.0 
	move Table_package.vhd %tableVHD%

	call :concat_stats %1
	call :move_stats %1
    call :call_simulation %1	
				
exit /b

:call_simulation
	call cd Teste
	call lote.bat %1
	call cd ..
exit /b
	
:concat_stats
	type ard >> relat-%1%
	echo. >> relat-%1%
	type lw-Mean >> relat-%1%
	echo. >> relat-%1%
	type lw-Std >> relat-%1%
	echo. >> relat-%1%
	type region-max >> relat-%1%
	echo. >> relat-%1%
	type unitSeg >> relat-%1%
	echo. >> relat-%1%
	type RegSeg >> relat-%1%
	echo. >> relat-%1%
	type topDist >> relat-%1%
	echo. >> relat-%1%
	type topDist-Std >> relat-%1%
	echo. >> relat-%1%
exit /b
	
:move_stats
	move ./relat-%1% ./Stats

exit /b

