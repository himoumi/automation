@echo off &setlocal
setlocal enabledelayedexpansion
Rem Program is designed to automate the Post Refresh Steps that has been done in WZRefresh. 
@echo Post Refresh Automation
Rem We need SFDX CLI & followed with the environment variable in Windows system.
@echo Make Sure SFDX CLI and Path variable are set for executing this script
Rem CLI Alias name for connecting the New Developer org. Do use the urlName and it has a dependency on updating the label
@echo -----------------------------------------------------------------------------------
@echo Do use the urlName as alias name because it has a dependency on updating the label
@echo Ex: URL https://cognizant--wzrefpro.lightning.force.com 
@echo Suggested AliasName to use is "wzrefpro"
@echo -----------------------------------------------------------------------------------
set /p AliasName="Enter the Salesforce AliasName for CLI connection: "
Rem CLI Salesforce Username for the Developer org to Perform the Post Refresh Automation
set /p UserName="Enter the Salesforce UserName used for above CLI connection: "
Rem CLI Auth Command to Login the new Developer Org and will redirect to login page followed with provide UserName and Password followed with allowing the CLI.
rem sfdx force:auth:web:login -a %AliasName% -r "https://test.salesforce.com"
Rem CLI Setting the Default Connection in CLI for permorming the Data activities
@echo -----------------------------------------------------------------------------------
@echo Setting the Default Username to New Org for Custom Setting update
@echo -----------------------------------------------------------------------------------
sfdx force:config:set defaultusername=%AliasName% -g
Rem Updating the Global Setting DE Team DL’s from receiving email for deals qualifying for ‘Delivery Assessment’
@echo Updating the Global Setting DE Team DLs from receiving email for deals qualifying for Delivery Assessment
Rem sfdx force:data:record:update -s Global_Setting__c -w "Name='DE_Team_Member_1'" -v "Value__c='shyamsundar.s@cognizant.com'"
Rem Updating the Global Setting to replace the value of the ‘Default Contact Email for Notification’ to dummy email
@echo Updating the Global Setting to replace the value of the Default Contact Email for Notification to dummy email
Rem sfdx force:data:record:update -s Global_Setting__c -w "Name='Default Contact Email for Notification'" -v "Value__c='WinZoneHelpDesk@example.com'"
Rem Updating the Global Setting to replace the value of the Proposal CoE Support DL from receiving email for deals qualifying to dummy email
@echo Updating the Global Setting to replace the value of the Proposal CoE Support DL from receiving email for deals qualifying to dummy email
Rem sfdx force:data:record:update -s Global_Setting__c -w "Name='ProposalCoESupportForStrategicEmail'" -v "Value__c='ProposalCoEsupport@example.com'"
Rem Moving to the Project Folder as scripts are maintained in .\PostRefreshAuto\scripts\batch
cd ..\..
Rem Moving to the label folder
cd force-app\main\default\labels
Rem Searching for the String wzrefpro and adjusting the URL update on the label meta file for the deployment.
Rem Label EmailNotificationBaseURL & NominateForEventURL (OrgName) 

@echo -----------------------------------------------------------------------------------
@echo Custom Label adjusted to EmailNotificationBaseURL and NominateForEventURL based on the AliasName
@echo -----------------------------------------------------------------------------------
set "search=wzdevops8"
set "replace=%AliasName%"
set "originalfile=CustomLabels.labels-meta.xml"
set "textfile=CustomLabels.labels-meta.xml"
set "newfile=CustomLabels_copy.labels-meta.xml"
(for /f "delims=" %%i in (%textfile%) do (
    set "line=%%i"
    set "line=!line:%search%=%replace%!"
    @echo(!line!
))>"%newfile%"
PAUSE
Rem Profile Tab adjustment using the SOQL 
sfdx force:data:soql:query -q "SELECT Id FROM user WHERE email = 'shyamsundar.s@cognizant.com'" > user.txt

rem Initialize the output line
set "line="

rem Catenate all file lines in the same variable separated by "|"
for /F "delims=" %%a in (user.txt) do set "line=!line!|%%a"

@echo !line:~1!
rem Show final line, removing the leading "|"
@echo !line:~1!>soqlUserOut.txt
rem result
rem wait
set /P Variable=<soqlUserOut.txt
echo "!Variable!"
dir
FOR /f "tokens=3 delims=|" %%a IN ("!Variable!") DO (
	@echo -----------------------------------------------------------------------------------
	@echo SFDCID="Enter the Salesforce ID from %AliasName% to replace it for Notify_Owner_Email label: %%a"
	@echo -----------------------------------------------------------------------------------
	set "search=123456"
	set "replaceUSerID=%%a"
	set "textfile=CustomLabels_copy.labels-meta.xml"
	set "newfile=CustomLabels_copy1.labels-meta.xml"
	(for /f "delims=" %%i in (%textfile%) do (
		set "line=%%i"
		set "line=!line:%search%=%replaceUSerID%!"
		@echo(!line!
	))>"%newfile%"
	del %originalfile%
	del %textfile%
	rename %newfile% %originalfile%
)
PAUSE
del user.txt
del soqlUserOut.txt
@echo Custom Label are modified at the local directory for deployment.
cd ../../../..
@echo -----------------------------------------------------------------------------------
@echo MDAPI Local modified Source file is converted to Metadata based on the Package
sfdx force:source:convert -d .\metaoutput -x .\manifest\package.xml
@echo MDAPI Deploying the Metadata to the New Developer Org (%AliasName%)
@echo -----------------------------------------------------------------------------------
sfdx force:mdapi:deploy -d .\metaoutput\ -u %UserName% -w -1 -c
@echo -----------------------------------------------------------------------------------
@echo Reverting the Label to Original File to reuse the same project folder for other Post Refresh 
cd force-app\main\default\labels
set "search=%AliasName%"
set "replace=wzdevops8"
rem set "originalfile=CustomLabels.labels-meta.xml"
set "textfile=CustomLabels.labels-meta.xml"
set "newfile=CustomLabels_copy.labels-meta.xml"
(for /f "delims=" %%i in (%textfile%) do (
    set "line=%%i"
    set "line=!line:%search%=%replace%!"
    @echo(!line!
))>"%newfile%"
set "search=%replaceUSerID%"
set "replace=123456"
set "textfile=CustomLabels_copy.labels-meta.xml"
set "userfile=CustomLabels_copy1.labels-meta.xml"
(for /f "delims=" %%i in (%textfile%) do (
    set "line=%%i"
    set "line=!line:%search%=%replace%!"
    @echo(!line!
))>"%newfile%"
PAUSE
del %originalfile%
del %textfile%
rename %userfile% %originalfile%
cd ../../../..
@echo Removing the metaoutput folder from Local as a cleansing process
@echo -----------------------------------------------------------------------------------
rem rmdir metaoutput /s /q

Rem Profile Tab adjustment using the SOQL 
sfdx force:data:soql:query -q "SELECT Id FROM PermissionSetTabSetting WHERE Parent.Profile.Name = 'System Administrator' and Name = 'Package_Creator'" > test.txt

rem Initialize the output line
set "line="

rem Catenate all file lines in the same variable separated by "|"
for /F "delims=" %%a in (test.txt) do set "line=!line!|%%a"

@echo !line:~1!
rem Show final line, removing the leading "|"
@echo !line:~1!>soqlOut.txt
rem result
rem wait
set /P Variable=<soqlOut.txt
echo "!Variable!"

FOR /f "tokens=3 delims=|" %%a IN ("!Variable!") DO (
   echo %%a
   sfdx force:data:record:update -s PermissionSetTabSetting -w "ID='%%a'" -v "Visibility='DefaultOn'"
)
del test.txt
del soqlOut.txt
@echo We have successfully executed the script. 
@echo Thank You 
PAUSE