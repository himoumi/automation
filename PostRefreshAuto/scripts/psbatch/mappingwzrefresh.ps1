#To Aumate the step of Mapping Object this file was created. This will pull the latest Mapping data from wzrefresh and 
#store in CSV. As of now this is not used, as the latest data is pulled from Prod and the CSV is stored directly in queryCSV.
Write-Host -ForegroundColor green "Login to Winzone Refresh to get the data of Mapping object"
Write-Host "----------------------------------------------------------------------------------"
$AliasName = Read-Host -Prompt 'Enter the Salesforce AliasName for CLI connection: '
$UserName  = Read-Host -Prompt 'Enter the Salesforce UserName used for above CLI connection: '
$aliasUrl = "https://cognizant--"+$AliasName+".my.salesforce.com"
Write-Host -ForegroundColor green "Org Url to login: '$aliasUrl' "
sfdx force:auth:web:login -a $AliasName -r $aliasUrl
Write-Host "--------------------------------------------------------------------------------"
Set-Location "queryCsv"
$MappingQuery = "Select BU_DESC__c,BU_ID__c,Code_Indexing__c,COUNTRY_ID__c,COUNTRY__c,GM_DESC__c,GM_ID__c,MARKET_DESC__c,MARKET_ID__c,Name,RHMS_Vertical_Id__c,SBU1_DESC__c,SBU1_ID__c,SBU2_DESC__c,SBU2_ID__c,STATE_ID__c,SUBVERTICAL_DESC__c,SUBVERTICAL_ID__c,VERTICAL_DESC__c,VERTICAL_ID__c FROM Mapping__c"
Write-Host -ForegroundColor green "Fetch the Mapping__c data and store in CSV"
sfdx force:data:soql:query -q "$MappingQuery" -u="$UserName" -r=csv > Mapping__c_original.csv
#$csvFile = Import-Csv -Path '.\Mapping__c_original.csv'
Write-Host -ForegroundColor green "Check the CSV for extracted data"
Set-Location ..