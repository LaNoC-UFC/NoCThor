REM use: lote.bat test_name
@echo off
set comp=do comp.do; exit -f
set simul=do sim.do 
REM ; exit -sim; exit -f
set test=%1
set output=.\Out\%test%
set input=..\%test%
rmdir /s /q work
echo %comp% | vsim.exe -c

mkdir %output%

for /d %%i in (%input%\*) do call :for_body %%i
exit /b

:for_body
	echo %1
	copy %1\In\in* .\In
	echo %simul% | vsim.exe -c
	del .\In\in*
	mkdir %output%\%1
	move .\Out\out* %output%\%1
exit /b

