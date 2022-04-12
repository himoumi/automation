#This file has been created for tesing purpose. Can be deleted later.
$AliasName = Read-Host -Prompt 'Enter the Salesforce AliasName for CLI connection: '
$UserName  = Read-Host -Prompt 'Enter the Salesforce UserName used for above CLI connection: '
#Write-Host "You input details '$AliasName' and '$UserName'"
Write-Host -ForegroundColor green "`n:: Authenticating to Salesforce with '$AliasName' and '$UserName'::"
#sfdx force:auth:web:login -a $AliasName -r "https://test.salesforce.com"
$aliasUrl = "https://cognizant--"+$AliasName+".my.salesforce.com"
Write-Host -ForegroundColor green "Org Url : '$aliasUrl' "
sfdx force:auth:web:login -a $AliasName -r $aliasUrl
#$addQuery = "SELECT Id,Name,Value__c FROM Global_Setting__c where Name in ('Contractccaddress','GGMSalesOpsDL','WinOppsDL','ProposalCoESupportForStrategicEmail','L2_Team_Notification','Default Contact Email for Notification','DE_Team_Member_1','ITFndSMEDL')"
#sfdx force:data:soql:query -q "$addQuery" -u="$UserName" -r=csv > globalSetting.csv
Set-Location "queryCsv"
Write-Host -ForegroundColor green "Insert the Mapping object data of wzrefresh"

if($AliasName -ne "wzrefresh" -or $AliasName -ne "test" -or $AliasName -ne "stagesb"){
    Write-Host -ForegroundColor red "Org Name : '$AliasName'"
    sfdx force:data:bulk:upsert -s Mapping__c -f Sandbox_Refresh_Mapping_Insert_LR.csv -i Id -w 2
}
if ((Test-Path -Path '.\Mapping__c_original.csv' -PathType Leaf) -or
                    (Test-Path -Path '.\Mapping__c_copy.csv' -PathType Leaf)){
       Write-Host -ForegroundColor red "Files exist.. removing them"
        Remove-Item .\Mapping__c_copy.csv
        Remove-Item .\Mapping__c_original.csv
}
Set-Location ..

