<#

.SYNOPSIS
	Configures a web application folder as an IIS Web Site.

.DESCRIPTION
	This script configures a local IIS website and application pool to run on the local host.

.PARAMETER applicationDirectory
	Specifies the source folder for the web application. The folder has to be existing and has all the web application files in it.

.PARAMETER siteAlias
	Specifies the Web Site and application pool name in the IIS configuration. If there is already a site with the same name, its configuration will be updated automatically.

.PARAMETER protocol
	Specifies the used protocol for the web site. It can be either 'http' or 'https'. If it is not provided it will be 'http' and 'https' with ports 80 and 443 respectively by default.

.PARAMETER portNo
	Specifies the Web Site port number. If it is not provided it will get the port number 80 (or 443 in case of https) by default.

.EXAMPLE
	Create-WebSite -applicationDirectory "C:\WebSite" -siteAlias "New Site" -protocol https -portNo 886

	This example creates and configures a http IIS website 'New Site' to the "C:\WebSite" physical path with the port number 886. Also creates an application pool with the name "New Site".

#>

param(
	[Parameter(Mandatory=$true, HelpMessage="The physical path where the web application located")]
	[ValidateNotNullorEmpty()]
	[string]$applicationDirectory,

	[Parameter(Mandatory=$true, HelpMessage="An alias name for the website which will be registered in IIS")]
	[ValidateNotNullorEmpty()]
	[string]$siteAlias,

	[Parameter(Mandatory=$false, HelpMessage="The used protocol for the web site - either http or https")]
	[ValidateSet("http", "https", $null)]
	[string]$protocol,

	[Parameter(Mandatory=$false, HelpMessage="The port number for the web site")]
	[uint16]$portNo
)

"Creating website..."

#region Variable Initialization

if (!($protocol -eq $null) -and !($protocol -eq "") -and $portNo -eq 0) {
	$portNo = if ($protocol -eq "https") { 443 } else { 80 }
}

$iisRoot = "IIS:\"
$appPoolPath = "IIS:\AppPools\$siteAlias"
$appWebSitePath = "IIS:\Sites\$siteAlias"

#endregion

#region Checking IIS

"Checking IIS..."

if (!(Test-Path $iisRoot)) {
	"  The PowerShell IIS module is not imported. Importing ..."
	Import-Module WebAdministration
}
	
#region Checking Application Pool

"Checking Application Pool..."

if (Test-Path $appPoolPath) {
	"  The '$siteAlias' application pool already exists."
	$appPool = Get-Item $appPoolPath
} else {
	"  The '$siteAlias' application pool does not exist. Creating application pool..."
	$appPool = New-Item $appPoolPath
}
	
"  Setting up .NET Framework version to 'v4.0' ..."
$appPool.managedRuntimeVersion = ""
	
"  Setting up Managed Pipeline mode to 'Integrated' ..."
$appPool.managedPipelineMode = "Integrated"
	
"  Disabling 32-Bit Applications mode ..."
$appPool.enable32BitAppOnWin64 = "false"
	    
"  Setting up Identity to 'Application Pool Identity' ..."
$appPool.processModel.identityType = "ApplicationPoolIdentity"
	
"  Disabling loading user profile ..."
$appPool.processModel.loadUserProfile = "false"
	
"  Disabling Ping for remote debugging ..."
$appPool.processModel.pingingEnabled = "false"
	
$appPool | Set-Item

#endregion

#region Checking Website

"Checking Website..."
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

#use http/80 and https/443 for bindings
if (($protocol -eq $null) -or ($protocol -eq "")) {
	"  Presetting the protocols to http and https with port numbers to 80 and 443 respectively ..."
	$bindings = @(
	   @{protocol="http";bindingInformation="*:80:"},
	   @{protocol="https";bindingInformation="*:443:"}
	)
}
#use specified protocol and port for bindings
else
{
	"  Presetting the protocol to '$protocol' and port number to $portNo ..."
	$bindings = @{ protocol=$protocol;bindingInformation="*:${portNo}:" }
}

if (!(Test-Path $applicationDirectory -pathType container)) {
	New-Item -ItemType Directory -Force -Path $applicationDirectory
}

if (!(Test-Path $appWebSitePath)) {
	$id = (dir iis:\sites | foreach {$_.id} | sort -Descending | select -first 1) + 1
	New-Website -Name "$siteAlias" -id $id -PhysicalPath "$applicationDirectory"
}

"  Setting the physical path to '$applicationDirectory' ..."
Set-ItemProperty $appWebSitePath -Name physicalPath -Value $applicationDirectory
"  Setting up the bindings ..."
Set-ItemProperty $appWebSitePath -Name bindings -Value $bindings    
"  Setting up application pool to '$siteAlias' ..."
Set-ItemProperty $appWebSitePath -Name applicationPool -Value $siteAlias

#endregion

"Create website done with no errors."