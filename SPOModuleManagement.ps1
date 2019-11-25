<#
.NOTES
    #######################################################################################################################################
    # Author: Jim B.
    #######################################################################################################################################
    # Revision(s)
    # 1.0.0 - 2019-11-25 - Initial Commit
    #######################################################################################################################################
.SYNOPSIS
    ...
.DESCRIPTION
    On Windows 10 - This script will attempt to configure Package Providers and Modules needed for operating SharePoint Online on Windows 10
.LINK
    ...
.EXAMPLE
    ...
#>
###########################################################################################################################################
#region - Variable(s)
$installPackageProviders = $true
$packageProviderNames = @(
    "NuGet",
    "PowerShellGet"
    )
$trustRepository = $false
$updateModules = $true
$ModuleNames = @(
    "AzureAD" ,
    "MSOnline",
    "AzureRM" ,
    "SharePointPnPPowerShellOnline" ,
    "Microsoft.Online.SharePoint.PowerShell"
    )
$saveModules = $false
$savedPowerShellModulesFolder = "C:\TEMP\SavedPowerShellModules" #will attempt creation if this folder does not exist
#endregion - Variable(s)
#region - Title
Clear-Host
Write-Host "M365 Module Management" -ForegroundColor Cyan
Write-Host "----------------------" -ForegroundColor Cyan
Write-Host
#endregion - Title
#region - Install Package Provider (Windows 10)
if ($installPackageProviders -eq $true)
    {
    Write-Host ("[Checking (" + $packageProviderNames.Count + ") Package Providers")
    $i = 0
    foreach ($packageProviderName in $packageProviderNames)
        {
        $i++
        Write-Host (" [" + $i + "/" + $packageProviderNames.Count + "] " + $packageProviderName) -NoNewline -ForegroundColor Gray
        $newestPackageProvider = Find-PackageProvider -Name $packageProviderName -AllVersions | Select-Object -First 1
        $installedPackageProvider = Get-PackageProvider -Name $packageProviderName  -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -InformationAction SilentlyContinue
        if ($installedPackageProvider -eq $null)
            {            
            Write-Host ("Installing Package Provider (" + $newestPackageProvider.Version + ")") -NoNewline
            Install-PackageProvider -Name $packageProviderName -MinimumVersion $newestPackageProvider.Version -Force
            Write-Host ("...Done" ) -ForegroundColor Green
            }
        else
            {        
            if ($newestPackageProvider.Version -gt $installedPackageProvider.Version)
                {
                Write-Host ("Updating: " + $installedPackageProvider.Name + " (" + $installedPackageProvider.Version + ") to Newest Version (" + $newestPackageProvider.Version + ")") -NoNewline
                Update-Module -Name $installedPackageProvider.Name -RequiredVersion $newestPackageProvider.Version -Confirm:$false
                Write-Host ("...Done" ) -ForegroundColor Green
                }  
            else
                {
                Write-Host (" - No Update Needed (" + $installedPackageProvider.Version + ")") -ForegroundColor Green
                }        
            }
        }
    }
#endregion - Install Package Provider (Windows 10)
#region - Trust Repository
if ($trustRepository -eq $true)
    {
    $PSRepository = Get-PSRepository
    if ($PSRepository.InstallationPolicy -eq "Untrusted")
        {
        Read-Host ("Are you sure you want to set " + $PSRepository.Name + " as a trusted PSRepository?")
        Set-PSRepository -Name $PSRepository.Name -InstallationPolicy Trusted
        }
    else
        {
        Write-Host (" - " + $PSRepository.Name + " Is already a trusted PSRepository") -ForegroundColor DarkGray
        }
    }
#endregion - Trust Repository
#region - Update Module(s)
if (!(Test-Path $savedPowerShellModulesFolder) -AND $saveModules -eq $true)
    {
    New-Item -Path $savedPowerShellModulesFolder -ItemType Directory | Out-Null
    }
if ($updateModules -eq $true)
    {
    Write-Host ("[Checking (" + $ModuleNames.Count + ") Modules]")
    $i = 0
    foreach ($ModuleName in $ModuleNames)
        {
        $i++
        Write-Host (" [" + $i + "/" + $ModuleNames.Count + "] " + $ModuleName) -NoNewline -ForegroundColor Gray
        $newestModule = Find-Module -Name $ModuleName -AllVersions | Select-Object -First 1
        $InstalledModule = Get-InstalledModule -Name $ModuleName -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -InformationAction SilentlyContinue    
        if ($InstalledModule -eq $null)
            {            
            Write-Host (" - Installing Module (" + $newestModule.Version + ")") -NoNewline
            Install-Module -Name $newestModule.Name -RequiredVersion $newestModule.Version -Confirm:$false
            Write-Host ("...Done" ) -ForegroundColor Green
            }
        else
            { 
            if ([version]$newestModule.Version -gt [version]$InstalledModule.Version)
                {
                Write-Host ("Updating: " + $InstalledModule.Name + " (" + $InstalledModule.Version + ") to Newest Version (" + $newestModule.Version + ")") -NoNewline
                Update-Module -Name $InstalledModule.Name -RequiredVersion $newestModule.Version -Confirm:$false
                Write-Host ("...Done" ) -ForegroundColor Green
                }  
            else
                {
                Write-Host (" - No Update Needed (" + $InstalledModule.Version + ")") -ForegroundColor Green
                }        
            }
        if ($saveModules -eq $true)
            {
            Write-Host (" - Saving Module (" + $newestModule.Version + ") to `"" + $savedPowerShellModulesFolder + "`"") -NoNewline
            Save-Module $newestModule.Name -Path $savedPowerShellModulesFolder -RequiredVersion $newestModule.Version
            Write-Host ("...Done") -ForegroundColor Green
            }
        }
    }
#endregion - Update Module(s)
#endregion - PowerShell Module Management
###########################################################################################################
