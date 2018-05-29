<#

.SYNOPSIS
	Configures a web package as an IIS Web Site.

.DESCRIPTION
	This script configures a local IIS website and application pool to run on the local host.

.PARAMETER packageLocation
	Specifies the package file and its source location.

.PARAMETER siteLocation
	Specifies the site location.

.EXAMPLE
	Deploy-WebSite.ps1 -packageLocation "C:\Package" -siteLocation "C:\Site"

	This example configures an IIS website located in "C:\Site" physical path using packages from "C:/Package".

#>

param(
	[Parameter(Mandatory=$true, HelpMessage="Specifies the package file and its source location")]
	[ValidateNotNullorEmpty()]
	[string]$packageLocation,

	[Parameter(Mandatory=$true, HelpMessage="Specifies the package file and its source location")]
	[ValidateNotNullorEmpty()]
	[string]$siteLocation
)

$MSDeployKey = 'HKLM:\SOFTWARE\Microsoft\IIS Extensions\MSDeploy\3'
if(!(Test-Path $MSDeployKey)) {
   throw "Could not find MSDeploy. Use Web Platform Installer to install the 'Web Deployment Tool' and re-run this command"
}
$InstallPath = (Get-ItemProperty $MSDeployKey).InstallPath
if(!$InstallPath -or !(Test-Path $InstallPath)) {
   throw "Could not find MSDeploy. Use Web Platform Installer to install the 'Web Deployment Tool' and re-run this command"
}

$msdeploy = Join-Path $InstallPath "msdeploy.exe"
if(!(Test-Path $MSDeploy)) {
   throw "Could not find MSDeploy. Use Web Platform Installer to install the 'Web Deployment Tool' and re-run this command"
}

# DEPLOY!
Write-Host "Deploying package from $packageLocation to $siteLocation"

$arguments = [string[]]@(
	"-verb:sync",
	"-source:contentPath='$packageLocation'",
	"-dest:contentPath='$siteLocation'"
	)

Start-Process $msdeploy -ArgumentList $arguments -NoNewWindow -Wait
