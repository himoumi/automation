@echo off &setlocal
setlocal enabledelayedexpansion
set /p firstLine=< BUHierarchy.csv
rem echo %firstLine% >> BUOut.csv
for /F "skip=1 usebackq delims=" %%# in ("BUHierarchy.csv") do (
    set "LINE=%%#"
	for /F "tokens=1-24 delims=," %%a in (^""!LINE:,="^,"!"^") do (
		rem echo %%a, %%b, "shyamsundar.s@cognizant.com", %%d, %%e, %%f, %%g, %%h, %%i, %%j, %%k, %%l, %%m, %%n, %%o, %%p, %%q, %%r, "akarsh.gupta@cognizant.com", %%t, %%u, %%v, %%w >>BuOut.csv
	)
)
endlocal
set "tempfile=filenametemp.txt"
for /F "tokens=1 skip=1 usebackq delims=" %%# in ("BUOut.csv") do (
	set "LINE=%%#"
    for /F "tokens=1-24 delims=," %%a in (^!LINE:,"!"^",="^) do(
		echo Hi
	)
)
endlocal
rem sfdx force:data:bulk:upsert -s BUHierarchy__c -f ./BUHierarchy.csv -i Name -u %UserName%
rem del BUHierarchy.csv
@echo We have successfully executed the script. 
@echo Thank You 
PAUSE