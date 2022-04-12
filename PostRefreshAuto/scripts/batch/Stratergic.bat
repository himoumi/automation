@echo off &setlocal
setlocal enabledelayedexpansion
sfdx force:config:set defaultusername=wzdevops15 -g
sfdx force:data:soql:query -q "SELECT ID,Name,ccSPGAddresses__c,toSPGAddresses__c FROM Strategic_Partner_Group_Setting__c" -r csv >> Strategic_Partner_Group_Setting.csv

set "search=.com"
set "replace=.com.invalid"
set "originalfile=Strategic_Partner_Group_Setting.csv"
set "textfile=Strategic_Partner_Group_Setting.csv"
set "newfile=Strategic_Partner_Group_Setting2.csv"
(for /f "delims=" %%i in (%textfile%) do (
    set "line=%%i"
    set "line=!line:%search%=%replace%!"
    @echo(!line!
))>"%newfile%"
del %originalfile%
rename %newfile% %originalfile%

rem sfdx force:data:bulk:upsert -s Strategic_Partner_Group_Setting__c -f ./Strategic_Partner_Group_Setting.csv -i Name -u %UserName%
del Strategic_Partner_Group_Setting.csv
@echo We have successfully executed the script. 
@echo Thank You 
PAUSE