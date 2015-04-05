REM use: simul.bat tables traffics
@echo off

if -%1-==-- echo Argument one not provided & exit /b
if -%2-==-- echo Argument one not provided & exit /b

set tables=%1
set traffics=%2

for %%s in (%tables%\*.vhd) do call :run_scen %%s
exit /b

REM run_scen noc
:run_scen
	echo %~nx1
	copy .\tables\%~nx1 .\Teste\NoC\Table_package.vhd
	call cd Teste
	rmdir /s /q work
	set comp=do comp.do; exit -f
	echo %comp% | vsim.exe -c
	for /d %%t in (..\%traffics%\*) do call :run_traff %1 %%t
	call cd ..
exit /b

REM run_traff noc traffic
:run_traff
	echo %1 %2
	for /d %%t in (..\%~n2\F*) do call :run_load %1 %2 %%t
exit /b

REM run_load noc traffic load
:run_load
	echo %~n1 %~n2 %~n3
	copy ..\traffics\%~n2\%~n3\In\in* .\In
	set simul=do sim.do
	echo %simul% | vsim.exe -c
	del .\In\in*
	set output=..\Output\%~n1\%~n2\%~n3
	mkdir output
	move .\Out\out* %output%
exit /b
