###########################################################################################################
#region - This SCRIPT should NOT be Run 'as a whole'
Clear-Host
Write-Host 'This SCRIPT should NOT be Run as a whole' -ForegroundColor Red
exit
#endregion - This SCRIPT should NOT be Run 'as a whole'
###########################################################################################################
#region - Cred
$tenantName = ""
# GLOBAL TENANT ADMIN CREDENTIALS
$globalAdminName = "admin"
$passwordString = 'pass@word1'
#endregion - Cred
###########################################################################################################
#region -  QUICK START
$adminUsername = "$globalAdminName@$tenantName.onmicrosoft.com"
$securePassword = ConvertTo-SecureString -String $passwordString -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $adminUsername, $securePassword
#MANUAL ENTRY: $cred = Get-Credential -Message "Please Enter Your Password:" -UserName 
#NOTE - This ONLY works if you do NOT have MFA enabled
#
#Open Browser to SPO Admin Page
$spoAdminUrl = ("https://" + $tenantName + "-admin.sharepoint.com")
& "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" --incognito $spoAdminUrl
Set-Clipboard -Value $adminUsername
Set-Clipboard -Value $passwordString
#
#Open Browser to SPO Root Site
$spoUrl = ("https://" + $tenantName + ".sharepoint.com")
& "C:\Program Files\Internet Explorer\iexplore.exe" -private $spoUrl
Set-Clipboard -Value $adminUsername ; Start-Sleep -Seconds 12 ; Set-Clipboard -Value $null
Set-Clipboard -Value $passwordString; Start-Sleep -Seconds 12 ; Set-Clipboard -Value $null
#
Connect-MsolService -Credential $cred
#
Connect-SPOService -Url $spoAdminUrl -Credential $cred
#
Connect-PnPOnline -Url "https://$tenantName.sharepoint.com" -Credentials $cred
#
Connect-MicrosoftTeams -Credential $cred
#
#endregion -  QUICK START
###########################################################################################################
#region - Remote PowerShell for SharePoint Online
# https://www.microsoft.com/en-us/download/details.aspx?id=35588
# Root SP Site: https://$tenantName.sharepoint.com
#
# List commands
Get-Command –Module Microsoft.Online.SharePoint.PowerShell
Get-Command *-SPO*

$sites = Get-SPOSite
foreach ($site in $sites)
    {
    $site
    }

#Some Example Commandlets
#FILTER SPO SITE LISTS
Get-SPOSite –Detailed | Format-Table Url, CompatibilityLevel
Get-SPOSite -Detailed | Format-Table Url, Template, Owner, SharingCapability -AutoSize
Get-SPOSite -Detailed | Format-Table Url, SharingCapability -AutoSize
Get-SPOSite -Detailed | ft url, storageusagecurrent, storagequota
Get-SPOSite -Detailed | ?{($_.storageusagecurrent / $_.storagequota) -gt 0.5}
Get-SPOSite -Detailed | ?{($_.storageusagecurrent / $_.storagequota) -gt 0.0000001}
Get-SPOSiteGroup -Site $site -Group

#GROUPS
$SPOSiteGroups = Get-SPOSiteGroup $SPOSite
foreach ($SPOSiteGroup in $SPOSiteGroups)
    {
    $SPOSiteGroup.Title
    Get-SPOUser -Site $SPOSite -Group $SPOSiteGroup.Title
    }
Test-SPOSite -Identity $SPOSite 
Get-SPOUser $SPOSite -Group "Team Site Members“
Set-SPOUser -Site https://$tenantName.sharepoint.com/sites/teamsite2 -LoginName "admin@$tenantName.onmicrosoft.com" -IsSiteCollectionAdmin $true
$SPOSite1 = Get-SPOSite https://$tenantName.sharepoint.com/sites/teamsite1
Get-SPOExternalUser -Position 0 -PageSize 10 -SiteUrl $SPOSite1.Url

#EXTERNAL SHARING

#SPO Site
$SPOSite = Get-SPOSite https://$tenantName.sharepoint.com
$SPOSite.DisableSharingForNonOwnersStatus
$sharingSite = Get-SPOSite https://$tenantName.sharepoint.com/sites/alexd
$sharingSite.SharingCapability
$sharingSite.ShowPeoplePickerSuggestionsForGuestUsers = $true
#Disable Sharing on ODfB SC
Get-SPOSite -Identity ("https://" + $tenantName + "-my.sharepoint.com/personal/admin_" + $tenantName + "_onmicrosoft_com")| Format-Table Url, Lockstate, Template, Owner, SharingCapability
$ODfBSite = Get-SPOSite -Identity ("https://" + $tenantName + "-my.sharepoint.com/personal/admin_" + $tenantName + "_onmicrosoft_com")
Set-SPOSite $ODfBSite -SharingCapability Disabled

#TENANT
$spoTenant = Get-SPOTenant
$spoTenant.ShowPeoplePickerSuggestionsForGuestUsers
Set-SPOTenant –SharingCapability ExistingExternalUserSharingOnly
Set-SPOTenant –SharingCapability ExternalUserAndGuestSharing
Set-SPOTenant –SharingCapability ExternalUserSharingOnly
Set-SPOTenant –SharingCapability Disabled
Set-SPOTenant -RequireAcceptingAccountMatchInvitedAccount $true

#Untested
Get-SPOAppInfo -Name "Nintex" #http://chen.about-powershell.com/2016/01/get-spoappinfo-sharepoint-online-powershell/
Get-SPOAppErrors
Get-SPOTenantSyncClientRestriction
Get-SPOExternalUser -SiteUrl https://$tenantName.sharepoint.com/sites/teamsite2  -Position 0 -PageSize 30

# Create  Site
New-SPOSite -Url https://$tenantName.sharepoint.com/sites/BLANKINTERNETCONTAINER0-01-VANILLA -Owner admin@$tenantName.onmicrosoft.com –Template BLANKINTERNETCONTAINER#0 –Storagequota 500
New-SPOSite -Url https://$tenantName.sharepoint.com/sites/STS0-01-VANILLA -Owner admin@$tenantName.onmicrosoft.com –Template STS#0 –Storagequota 500
New-SPOSite -Url https://$tenantName.sharepoint.com/sites/STS3-01-VANILLA -Owner admin@$tenantName.onmicrosoft.com –Template STS#3 –Storagequota 500

# Create Multiple Sites via CSV
$labFilesLocation = "C:\temp\"
$sites = Import-Csv ($labFilesLocation + "bulkcreatesites.csv") #| where {$_.url -notlike "*marketing*"}
$sites
$root = "https://$tenantName.sharepoint.com/sites/"
foreach($site in $sites) {
    New-SPOSite -url ($root+$site.url) -Owner $site.owner -StorageQuota $site.storage -Title $site.title -Template $site.template –NoWait
    Write-Host "Created site at" ($root+$site.url)
}

#region - Create Various SPOSites from Hash Table
$NewTeamSites = @(
        ("ModernTeamSite","STS#3"),
        ("ClassicTeamSite","STS#0"),
        ("DocumentCenter","BDR#0"),
        ("RecordCenter","OFFILE#1"),
        ("SPOTeamSite","EHS#1"),
        ("EnterPriseWiki","ENTERWIKI#0"),
        ("CTHUB","STS#0"),
        ("PRODUCTCATALOG","PRODUCTCATALOG#0")
        )  

foreach ($NewTeamSite in $NewTeamSites)
    {
    #region - Variables
    $SiteToCreateUrl = ("https://" + $tenantName + ".sharepoint.com/sites/" + $NewTeamSite[0])    
    $SiteToCreateTitle = $NewTeamSite[0]
    $SiteToCreateTemplate = $NewTeamSite[1]    
    $StorageQuota = 100
    #endregion - Variables
    Write-Host ("Creating site: " + $SiteToCreateUrl) -NoNewline
    New-SPOSite -Url $SiteToCreateUrl -Owner "admin@$tenantName.onmicrosoft.com"-Template $SiteToCreateTemplate -StorageQuota $StorageQuota -Title $SiteToCreateTitle -NoWait
    Write-Host ("...Queued") -ForegroundColor Green
    }
#endregion - Create Various SPOSites from the Hash Table

#region - Create Site for Each SPOWebTemplate
$allSPOWebTemplates = Get-SPOWebTemplate
foreach ($SPOWebTemplate in $allSPOWebTemplates)
    {    
    $NewSiteUrl = $SPOWebTemplate.Title.Replace(" ","")
    $NewSiteUrl = $NewSiteUrl.Replace("(","")
    $NewSiteUrl = $NewSiteUrl.Replace(")","")
    $NewSiteUrl     
    #region - Variables
    $SiteToCreateUrl = ("https://" + $tenantName + ".sharepoint.com/sites/" + $NewSiteUrl)    
    $SiteToCreateTitle = $NewSiteUrl
    $SiteToCreateTemplate = $SPOWebTemplate.Name  
    $StorageQuota = 100
    #endregion - Variables
    
    Write-Host ("Creating site: " + $SiteToCreateUrl) -NoNewline
    New-SPOSite -Url $SiteToCreateUrl -Owner "admin@$tenantName.onmicrosoft.com"-Template $SiteToCreateTemplate -StorageQuota $StorageQuota -Title $SiteToCreateTitle -NoWait
    Write-Host ("...Queued") -ForegroundColor Green
    }
#endregion - Create Site for Each SPOWebTemplate

#Lock A Site collection
Set-SPOSite https://$tenantName.sharepoint.com/sites/marketing -lockstate NoAccess
Set-SPOTenant -NoAccessRedirectURL http://www.bing.com

#UnLock A Site collection
Set-SPOSite https://$tenantName.sharepoint.com/sites/marketing -lockstate Unlock
#
Get-SPOTenantLogEntry

#DELETE & RECOVER SPO SITE
Remove-SPOSite -Identity https://$tenantName.sharepoint.com/sites/teamsite2 -Confirm:$false
Get-SPODeletedSite |fl
Restore-SPODeletedSite -Identity https://$tenantName.sharepoint.com/sites/teamsite2 -NoWait

#SPO SITE THEME
$themepallette = @{
"themePrimary" = "#ff8e00";
"themeLighterAlt" = "#fffaf5";
"themeLighter" = "#ffedd6";
"themeLight" = "#ffddb3";
"themeTertiary" = "#ffba66";
"themeSecondary" = "#ff9a1f";
"themeDarkAlt" = "#e67e00";
"themeDark" = "#c26b00";
"themeDarker" = "#8f4f00";
"neutralLighterAlt" = "#dddddd";
"neutralLighter" = "#d9d9d9";
"neutralLight" = "#d0d0d0";
"neutralQuaternaryAlt" = "#c2c2c2";
"neutralQuaternary" = "#b9b9b9";
"neutralTertiaryAlt" = "#b2b2b2";
"neutralTertiary" = "#595959";
"neutralSecondary" = "#373737";
"neutralPrimaryAlt" = "#2f2f2f";
"neutralPrimary" = "#ffffff";
"neutralDark" = "#151515";
"black" = "#0b0b0b";
"white" = "#ffffff";
"bodyBackground" = "#e2e2e2";
"bodyText" = "#000000";
#USED TO MISS TWO ENTRIES
}

# Prepare the Theme Color Palette
$themeColorPallette = @{
"themePrimary" = "#0078d4";
"themeLighterAlt" = "#eff6fc";
"themeLighter" = "#deecf9";
"themeLight" = "#c7e0f4";
"themeTertiary" = "#71afe5";
"themeSecondary" = "#2b88d8";
"themeDarkAlt" = "#106ebe";
"themeDark" = "#005a9e";
"themeDarker" = "#004578";
"neutralLighterAlt" = "#f8f8f8";
"neutralLighter" = "#f4f4f4";
"neutralLight" = "#eaeaea";
"neutralQuaternaryAlt" = "#dadada";
"neutralQuaternary" = "#d0d0d0";
"neutralTertiaryAlt" = "#c8c8c8";
"neutralTertiary" = "#595959";
"neutralSecondary" = "#373737";
"neutralPrimaryAlt" = "#2f2f2f";
"neutralPrimary" = "#000000";
"neutralDark" = "#151515";
"black" = "#0b0b0b";
"white" = "#ffffff";
"primaryBackground" = "#ffffff";
"primaryText" = "#000000";
"bodyBackground" = "#ffffff";
"bodyText" = "#000000";
"disabledBackground" = "#f4f4f4";
"disabledText" = "#c8c8c8";
}
# Add the theme to the Tenant (will be availble for selection on all MODERN Sites)
Add-SPOTheme -Name "NewThemeName001" -Palette $themeColorPallette -IsInverted $false
#Remove the theme from the Tenant
Remove-SPOTheme -Name "NewThemeName001"
#endregion - Add/Remove a SPO Theme to the Tenant

#HUB SITES
Register-SPOHubSite -Site https://$tenantName.sharepoint.com/sites/TeamHub
gcm *SPO*hub*
#region - Add/Remove a SPO Theme to the Tenant
# http://aka.ms/spthemebuilder
# https://developer.microsoft.com/en-us/fabric#/styles/themegenerator
# https://www.origamiconnect.com/blog/sharepoint-modern-themes

#New SPO Commands
Set-SPOBrowserIdleSignOut -Enabled $true -WarnAfter (New-TimeSpan -Seconds 30) -SignOutAfter (New-TimeSpan -Seconds 60)
Start-SPOUserAndContentMove -UserPrincipalName "" -DestinationDataLocation EUR

#ONEDRIVE FOR BUSINESS
Set-SPOTenantSyncClientRestriction -GrooveBlockOption "HardOptIn" 
#The SoftOptIn parameter is currently not supported.

#endregion - Remote PowerShell for SharePoint Online
###########################################################################################################

###########################################################################################################
#region - SharePoint Migration Tool
#
#https://docs.microsoft.com/en-us/sharepointmigration/new-and-improved-features-in-the-sharepoint-migration-tool
#Module Gets installed automatically when you install the SPMT
Import-Module Microsoft.SharePoint.MigrationTool.PowerShell
Get-Command *SPMT* | Format-Table Name, Version, Source -AutoSize
#
Add-SPMTTask      
Get-SPMTMigration       
Register-SPMTMigration  
Remove-SPMTTask         
Show-SPMTMigration      
Start-SPMTMigration     
Stop-SPMTMigration      
Unregister-SPMTMigration
#
#DOMAIN User SID
Get-WmiObject win32_useraccount -Filter ("Domain='domain.com' AND Name='alias'")
#LOCAL User SID
Get-WmiObject win32_useraccount -Filter ("Domain='" + $env:COMPUTERNAME + "'") | Where-Object {$_.Disabled -eq $false}
Get-WmiObject win32_useraccount -Filter ("Domain='" + $env:COMPUTERNAME + "' AND Name='administrator'")
#endregion - SharePoint Migration Tool
###########################################################################################################
#region - OfficeDev - SharePoint Patterns and Practices PowerShell Cmdlets for SharePoint Online
#https://blogs.technet.microsoft.com/dawiese/2017/02/15/powershell-modules-for-managing-sharepoint-online
#region - PnP Stuff
(Get-Command -Module *PnP*).Count
Get-Command *PnP*Site*
$rootConnection = Connect-PnPOnline -Url "https://$tenantName.sharepoint.com" -Credentials $cred
Connect-PnPOnline -Url $spoAdminUrl -Credentials $cred
Set-PnPWeb -AlternateCssUrl "/SiteAssets/contoso.css"
Set-PnPWeb -AlternateCssUrl ""
Set-PnPWeb -SiteLogoUrl "/SiteAssets/pnp.png"
Set-PnPWeb -SiteLogoUrl "/SiteAssets/Client files.jpg"
$pnpWeb = Get-PnPWeb
$pnpWeb.AlternateCssUrl
$pnpWeb.Update()
$cUIExtn = "<CommandUIExtension><CommandUIDefinitions><CommandUIDefinition Location=""Ribbon.List.Share.Controls._children""><Button Id=""Ribbon.List.Share.GetItemsCountButton"" Alt=""Get list items count"" Sequence=""11"" Command=""Invoke_GetItemsCountButtonRequest"" LabelText=""Get Items Count"" TemplateAlias=""o1"" Image32by32=""_layouts/15/images/placeholder32x32.png"" Image16by16=""_layouts/15/images/placeholder16x16.png"" /></CommandUIDefinition></CommandUIDefinitions><CommandUIHandlers><CommandUIHandler Command=""Invoke_GetItemsCountButtonRequest"" CommandAction=""javascript: alert('Total items in this list: '+ ctx.TotalListItems);"" EnabledScript=""javascript: function checkEnable() { return (true);} checkEnable();""/></CommandUIHandlers></CommandUIExtension>"
Add-PnPCustomAction -Name 'GetItemsCount' -Title 'Invoke GetItemsCount Action' -Description 'Adds custom action to custom list ribbon' -Group 'SiteActions' -Location 'CommandUI.Ribbon' -CommandUIExtension $cUIExtn
#
Set-PnPMinimalDownloadStrategy -Off #Site Feature
Get-PnpTheme
Get-PnPCustomAction
Get-PnPNavigationNode
Get-PnPSite
Get-PnPAuditing
Get-PnPWeb
New-PnPList -Title "Generic List2" -Template GenericList -Url "GenericList2"
Add-PnPField -List "Generic List2" -DisplayName "Location" -InternalName "SPSLocation" -Type Choice -Group "Demo Group" -Choices "New Delhi","Seattle","Shanghai" -AddToDefaultView
Disconnect-PnPOnline
#endregion - PNP Stuff
#endregion - OfficeDev - SharePoint Patterns and Practices PowerShell Cmdlets for SharePoint Online
#https://sharepoint.stackexchange.com/questions/176142/apply-alternate-css-to-all-site-collections-via-powershell-in-sharepoint-2013
###########################################################################################################
