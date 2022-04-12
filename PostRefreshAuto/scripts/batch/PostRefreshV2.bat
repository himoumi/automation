@echo off &setlocal
setlocal enabledelayedexpansion
Rem Program is designed to automate the Post Refresh Steps that has been done in WZRefresh.
@echo Post Refresh Automation
Rem We need SFDX CLI & followed with the environment variable in Windows system.

Rem CLI Alias name for connecting the New Developer org. Do use the urlName and it has a dependency on updating the label
@echo -----------------------------------------------------------------------------------
@echo Do use the urlName as alias name because it has a dependency on updating the label
@echo Ex: URL https://cognizant--wzrefpro.lightning.force.com 
@echo Suggested AliasName to use is "wzrefpro"
@echo -----------------------------------------------------------------------------------
set /p AliasName="Enter the Salesforce Alias Name for CLI connection: "
set /p UserName="Enter the Salesforce User Name used for above CLI connection: "
sfdx force:auth:web:login -a %AliasName% -r "https://test.salesforce.com"
sfdx force:config:set defaultusername=%AliasName% -g
sfdx force:data:record:update -s Global_Setting__c -w "Name='DE_Team_Member_1'" -v "Value__c='shyamsundar.s@cognizant.com'"
sfdx force:data:record:update -s Global_Setting__c -w "Name='Default Contact Email for Notification'" -v "Value__c='WinZoneHelpDesk@example.com'"
cd ..\..
cd force-app\main\default\labels
set "search=wzrefpro"
set "replace=%AliasName%"
set "originalfile=CustomLabels.labels-meta.xml"
set "textfile=CustomLabels.labels-meta.xml"
set "newfile=CustomLabels_copy.labels-meta.xml"
(for /f "delims=" %%i in (%textfile%) do (
    set "line=%%i"
    set "line=!line:%search%=%replace%!"
    echo(!line!
))>"%newfile%"
set /p SFDCID="Enter the Salesforce ID from %AliasName% to replace it for Notify_Owner_Email label: "
set "search=0053k00000B8OuXAAV"
set "replace=%SFDCID%"
set "textfile=CustomLabels_copy.labels-meta.xml"
set "newfile=CustomLabels_copy1.labels-meta.xml"
(for /f "delims=" %%i in (%textfile%) do (
    set "line=%%i"
    set "line=!line:%search%=%replace%!"
    echo(!line!
))>"%newfile%"
del %originalfile%
del %textfile%
rename %newfile% %originalfile%
cd ../../../..
sfdx force:source:convert -d .\metaoutput -x .\manifest\package.xml
sfdx force:mdapi:deploy -d .\metaoutput\ -u %UserName% -w -1 -c

cd force-app\main\default\labels
set "search=%AliasName%"
set "replace=wzdevops8"
set "originalfile=CustomLabels.labels-meta.xml"
set "textfile=CustomLabels.labels-meta.xml"
set "newfile=CustomLabels_copy.labels-meta.xml"
(for /f "delims=" %%i in (%textfile%) do (
    set "line=%%i"
    set "line=!line:%search%=%replace%!"
    echo(!line!
))>"%newfile%"
set "search=%SFDCID%"
set "replace=0053k00000B8OuXAAV"
set "textfile=CustomLabels_copy.labels-meta.xml"
set "newfile=CustomLabels_copy1.labels-meta.xml"
(for /f "delims=" %%i in (%textfile%) do (
    set "line=%%i"
    set "line=!line:%search%=%replace%!"
    echo(!line!
))>"%newfile%"
del %originalfile%
del %textfile%
rename %newfile% %originalfile%
cd ../../../..

PAUSE