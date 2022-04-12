#Write-Host "Congrates For installing Powershell successfully"
Write-Host -ForegroundColor green "Post Refresh Automation Started..."
Write-Host "---------------------------------------------------------------------"
Write-Host -ForegroundColor green "Do use the urlName as alias name because it has a dependency on updating the label ::"
Write-Host "Suggested AliasName to use is like : wzrefpro"
$AliasName = Read-Host -Prompt 'Enter the Salesforce AliasName for CLI connection: '
$UserName  = Read-Host -Prompt 'Enter the Salesforce UserName used for above CLI connection: '
#Write-Host "You input details '$AliasName' and '$UserName'"
Write-Host -ForegroundColor green "`n:: Authenticating to Salesforce with '$AliasName' and '$UserName'::"
sfdx force:auth:web:login -a $AliasName -r "https://test.salesforce.com"
#If any issue in login using test.salesforce.com, then comment Line 10 and uncomment the below 3 lines i.e. 12-14 
#$aliasUrl = "https://cognizant--"+$AliasName+".my.salesforce.com"
#Write-Host -ForegroundColor green "Org Url to login: '$aliasUrl' "
#sfdx force:auth:web:login -a $AliasName -r $aliasUrl
Write-Host "--------------------------------------------------------------------------------"
Write-Host -ForegroundColor green "Setting the Default Username to New Org for Custom Setting update"
sfdx force:config:set defaultusername=$AliasName -g
Write-Host "-----------------------------------------------------------------------------------"
#STEP 3 - Includes 7 custom setting changes
Write-Host -ForegroundColor blue "Update the Global/Custom Settings"
$addQuery = "SELECT Id,Name,Value__c FROM Global_Setting__c where Name in ('Contractccaddress','GGMSalesOpsDL','WinOppsDL','ProposalCoESupportForStrategicEmail','L2_Team_Notification','Default Contact Email for Notification','DE_Team_Member_1','ITFndSMEDL')"
sfdx force:data:soql:query -q "$addQuery" -u="$UserName" -r=csv > globalSetting.csv
$concatString = ".invalid"
$updFile = Import-Csv -Path '.\globalSetting.csv' 
#$updFile| ForEach-Object{ $_.Value__c  = $_.Value__c + $concatString } 
$updFile| ForEach-Object{ 
    $fieldvals = $_.Value__c
    $updval = New-Object System.Collections.Generic.List[string]
    foreach ($fieldval in $fieldvals -split ",") {
        $fieldval = $fieldval + $concatString
        $updval.Add($fieldval)
    }
    if($updval.Count -gt 1){
        $updval = $updval -join ','
    }
    $_.Value__c = $updval
    ##Write-Host $_.Value__c  	
} 
$updFile | ConvertTo-Csv -NoTypeInformation | Set-Content globalSetting_copy.csv
Write-Host -ForegroundColor green "Bulk Update Data for Global_Setting__c Object"
sfdx force:data:bulk:upsert -s Global_Setting__c -f globalSetting_copy.csv -i Id -w 2
#Update contact record only if the org is wzrefresh or winzoneuat
$query = "SELECT Id,Name, Email,Email__c From Contact where Name = 'WinZone HelpDesk'"
sfdx force:data:soql:query -q "$query" -u="$UserName" -r=csv > contactRecord.csv
if($AliasName -eq "wzrefresh" -or $AliasName -eq "wzuat"){
    Write-Host -ForegroundColor blue "Updating Contact Record for '$AliasName'"
    $updFile = Import-Csv -Path '.\contactRecord.csv' 
    $updFile| ForEach-Object{ 
        $_.Email    = $_.Email + $concatString ;
        $_.Email__c = $_.Email__c + $concatString
    } 
    $updFile | ConvertTo-Csv -NoTypeInformation | Set-Content contactRecord_copy.csv
    sfdx force:data:bulk:upsert -s Contact -f contactRecord_copy.csv -i Id -w 2    
    
    Remove-Item .\contactRecord_copy.csv
}
Remove-Item .\globalSetting.csv
Remove-Item .\globalSetting_copy.csv
Remove-Item .\contactRecord.csv
Write-Host "-------------------------------------------------------------------------------------------------"
#STEP 4 - Includes 10 custom label changes
Write-Host -ForegroundColor green "Update the custom Labels"
Set-Location ..\..
Set-Location "force-app\main\default\labels"
$orginalFile = "CustomLabels.labels-meta.xml"
$textFile = "CustomLabels.labels-meta.xml"
$newFile = "CustomLabels_copy.labels-meta.xml"
#$SFDCID = Read-Host -Prompt 'Enter the Salesforce ID from ORG to replace it for Notify_Owner_Email label: '
$pos = $UserName.LastIndexOf(".")
$userEmail = $UserName.Substring(0, $pos)
#$rightPart = $UserName.Substring($pos+1)
Write-Host "Email Of User : $userEmail"
sfdx force:data:soql:query -q "SELECT ID FROM USER WHERE Email= '$userEmail'" -r=csv > sfdc.csv
$SFDCID =  (Import-Csv .\sfdc.csv).Id | ForEach-Object{$_}
Write-Host "SFDCID : $SFDCID"
((Get-Content $textFile -Raw) | Foreach-Object {
   $_ -replace('wzrefpro',$AliasName)`
      -replace ('0053k00000B8OuXAAV',$SFDCID)
}) | Set-Content $newFile 
#$textFile = "CustomLabels_copy.labels-meta.xml"
#$newFile = "CustomLabels_copy1.labels-meta.xml"
#((Get-Content $textFile -Raw) -replace '123456',$SFDCID) | Set-Content $newFile
Remove-Item $orginalFile
Remove-Item .\sfdc.csv
Rename-Item $newFile -NewName $orginalFile
Write-Host -ForegroundColor blue "Custom Labels are modified at the local directory for deployment."
Set-Location ../../../..
#Set-Location "1791-PostRefresh\PostRefreshAuto"
Write-Host "--------------------------------------------------------------------------------------------"
# STEP - Deploy 1,2,4,6,Formula Field for Action Plan Id
Write-Host -ForegroundColor green "MDAPI Local modified Source file is converted to Metadata based on the Package"
sfdx force:source:convert -d .\metaoutput -x .\manifest\package.xml
Write-Host -ForegroundColor green "MDAPI Deploying the Metadata to the New Developer Org '$AliasName'"
sfdx force:mdapi:deploy -d .\metaoutput\ -u $UserName -w -1
Write-Host "--------------------------------------------------------------------------------------------"
Write-Host -ForegroundColor green "Reverting the Label to Original File to reuse the same project folder for other Post Refresh "
Set-Location "force-app\main\default\labels"
$orginalFile = "CustomLabels.labels-meta.xml"
$textFile = "CustomLabels.labels-meta.xml"
$newFile = "CustomLabels_copy.labels-meta.xml"
((Get-Content $textFile -Raw) | Foreach-Object {
    $_ -replace ($AliasName,'wzrefpro')`
       -replace ($SFDCID,'0053k00000B8OuXAAV')
}) | Set-Content $newFile 
Remove-Item $orginalFile
#Remove-Item $textFile
Rename-Item $newFile -NewName $orginalFile
Set-Location ../../../..
Write-Host "-------------------------------------------------------------------------"
Write-Host -ForegroundColor green "Removing the metaoutput folder from Local as a cleansing process"
Remove-Item metaoutput -Recurse
Write-Host "-------------------------------------------------------------------------"
#Step 8 - BU Hierarchy
#Set-Location ..\..
#Set-Location "force-app\main\default\queryCsv"
Set-Location "scripts\psbatch\queryCsv"
$BUHierchyQuery = "SELECT Additional_Mail_Strategic_Recipients__c,BU_COO__c,BU_Head__c,BU_Ops_Lead__c,BU_Top_Sheet_Short_Name__c,BU__c,Compliance_Lead_Name__c,CurrencyIsoCode,DeRisk_Manager__c,FUPA_Approvers__c,Global_Market_Top_Sheet_Short_Name__c,Global_Market__c,Id,Merge_Column_Name__c,Name,Sales_Director__c,SBU2_Lead__c,SBU2__c,SBU_Lead__c,SBU__c,SetupOwnerId,show_BU_in_Topsheet__c,show_GM_in_Topsheet__c,UnifiedGlobalMarket__c FROM BUHierarchy__c"
Write-Host -ForegroundColor green "Fetch the BUHierarchy__c data and store in CSV"
sfdx force:data:soql:query -q "$BUHierchyQuery" -u="$UserName" -r=csv > BUHierarchy__c_original.csv
Write-Host -ForegroundColor green "Make the required changes in the downloaded CSV"
((Get-Content BUHierarchy__c_original.csv -Raw) -replace '@cognizant.com','@example.com') | Set-Content original_copy.csv
$updFile = Import-Csv -Path '.\original_copy.csv'
Write-Host -ForegroundColor green " AliasName >>>>>>>> : '$AliasName' "
if($AliasName -eq "wzrefresh"){
    Write-Host -ForegroundColor blue " AliasName : '$AliasName' "
    $updFile | Foreach-Object {
        $_.BU_Head__c  = "Satish.Daregave@cognizant.com";
        $_.SBU_Lead__c = "Vamsi.Krishna8@cognizant.com" 
    }    
}
if($AliasName -eq "wzuat"){
    Write-Host -ForegroundColor blue " AliasName : '$AliasName' "
    $updFile | Foreach-Object {
        $_.BU_Head__c  = "Saravanan-9.G-9@cognizant.com";
        $_.SBU_Lead__c = "Emily.Allsop@cognizant.com" 
    }    
}
if($AliasName -eq "test"){
    Write-Host -ForegroundColor blue " AliasName : '$AliasName' "
    $updFile | Foreach-Object {
        $_.BU_Head__c  = "Parthiban.S3@cognizant.com";
        $_.SBU_Lead__c = "Venkatesh.Badugu@cognizant.com" 
    }
}else{
    Write-Host -ForegroundColor blue " AliasName : '$AliasName' "
    $updFile | Foreach-Object {
        $_.BU_Head__c  = "Akarsh.Gupta@cognizant.com";
        $_.SBU_Lead__c = "Pramit.Kumar2@cognizant.com" 
    } 
}
$updFile | ConvertTo-Csv -NoTypeInformation | Set-Content BUHierarchy__c_upd.csv
Write-Host -ForegroundColor blue "CSV Edited successfully"
Write-Host -ForegroundColor green "Bulk Update Data for BU_Hiererchy__c Object"
sfdx force:data:bulk:upsert -s BUHierarchy__c -f BUHierarchy__c_upd.csv -i Id -w 2
Write-Host "-----------------------------------------------------------------------------"
#STEP 9 - Strategic Partner Group Setting
Write-Host -ForegroundColor green "Fetch the data from Strategic_Partner_Group_Setting__c and store in CSV"
$StrategicQuery = "SELECT ccSPGAddresses__c,CurrencyIsoCode,Id,Name,SetupOwnerId,toSPGAddresses__c FROM Strategic_Partner_Group_Setting__c"
sfdx force:data:soql:query -q "$StrategicQuery" -u="$UserName" -r=csv > Strategic_Partner_original.csv
((Get-Content Strategic_Partner_original.csv -Raw) -replace '@cognizant.com','@example.com') | Set-Content Stp_original_copy.csv
Write-Host -ForegroundColor green "Bulk Update Data for Strategic_Partner_Group_Setting__c Object"
sfdx force:data:bulk:upsert -s Strategic_Partner_Group_Setting__c -f Stp_original_copy.csv -i Id -w 2
Write-Host "-----------------------------------------------------------------------------"
#STEP 10 - Account Plan Folder
Write-Host -ForegroundColor green "Fetch the data from Account_Plan_Folder__c and store in CSV"
$AcctPlanFolderQuery = "SELECT Id FROM Account_Plan_Folder__c"
sfdx force:data:soql:query -q "$AcctPlanFolderQuery" -u="$UserName" -r=csv > AccPlanFolder_original.csv
$csvFile = Import-Csv -Path '.\AccPlanFolder_original.csv'
$csvFile | ConvertTo-Csv -NoTypeInformation | Set-Content AccPlanFolder_copy.csv
Write-Host -ForegroundColor green "Bulk Delete Data for Account_Plan_Folder__c Object"
sfdx force:data:bulk:delete -s Account_Plan_Folder__c -f AccPlanFolder_copy.csv
Write-Host -ForegroundColor green "Bulk Insert Data for Account_Plan_Folder__c Object"
sfdx force:data:bulk:upsert -s Account_Plan_Folder__c -f Sandbox_Refresh_Account_Plan_Folder_LR.csv -i Id -w 2
Write-Host "-----------------------------------------------------------------------------"
#Due to the duplicate index issue this step has been commented as of now., If its resolved, uncomment the below 
#lines from 178 - 183 to automate this step.
#STEP 11 - Insert Mapping Object for dev and uat orgs except wzrefresh/stage/test
#$refreshMappingFile = Import-Csv -Path '.\Mapping__c_original.csv'
#$refreshMappingFile | ConvertTo-Csv -NoTypeInformation | Set-Content Mapping__c_copy.csv
#if($AliasName -ne "wzrefresh" -or $AliasName -ne "test" -or $AliasName -ne "stagesb"){
#    Write-Host -ForegroundColor green "Bulk Insert the Mapping object data of wzrefresh"
#    sfdx force:data:bulk:upsert -s Mapping__c -f Mapping__c_copy.csv -i Id -w 2
#}
Write-Host "------------------------------------------------------------------------------"
#Step 22 - Insert Validation Cut Off data in all orgs except wzrefresh/stage/test
if($AliasName -ne "wzrefresh" -or $AliasName -ne "test" -or $AliasName -ne "stagesb"){
    Write-Host -ForegroundColor green "Bulk Insert Data for Validation_Cut_Off_Date__c Object"
    sfdx force:data:bulk:upsert -s Validation_Cut_Off_Date__c -f Validation_Cut_Off_Date.csv -i Id -w 2
}
Write-Host "--------------------------------------------------------------------------------"
Write-Host "Remove the created CSV files from Local as a part of cleansing process "
Remove-Item .\BUHierarchy__c_upd.csv
Remove-Item .\BUHierarchy__c_original.csv
Remove-Item .\original_copy.csv
Remove-Item .\AccPlanFolder_copy.csv
Remove-Item .\AccPlanFolder_original.csv
Remove-Item .\Stp_original_copy.csv
Remove-Item .\Strategic_Partner_original.csv
#Uncomment the below lines if automating STEP 11
#if ((Test-Path -Path '.\Mapping__c_original.csv' -PathType Leaf) -or
#                    (Test-Path -Path '.\Mapping__c_copy.csv' -PathType Leaf)){
#        Remove-Item .\Mapping__c_copy.csv
#        Remove-Item .\Mapping__c_original.csv
#}
Write-Host "Removed items successfully "
Write-Host "-----------------------------------------------------------------------------"
#Set-Location ../../../..
Set-Location ../../..
#Set-Location "1791-PostRefresh\PostRefreshAuto"
Write-Host -ForegroundColor green "We have successfully executed the Post Refresh script." 
Write-Host -ForegroundColor green "Thank You "
