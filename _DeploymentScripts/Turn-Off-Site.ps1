<#

.SYNOPSIS
	Turn off WebSite and Application Pool

.DESCRIPTION
	This script turns off the specified IIS website and app pool

.PARAMETER siteAlias
	Specifies the Web Site and application pool name in the IIS configuration.

.EXAMPLE
	Turn-Off-Site -siteAlias "Site X"

	This example turns off the website and application pool with the name "Site X"

#>

param(
	[Parameter(Mandatory=$true, HelpMessage="An alias name for the website which will be registered in IIS")]
	[ValidateNotNullorEmpty()]
	[string]$siteAlias
)

"Turning Off Site '$siteAlias'...."

$appPoolPath = "IIS:\AppPools\$siteAlias"
$appWebSitePath = "IIS:\Sites\$siteAlias"

#region Turn off web site

if (Test-Path $appWebSitePath) {
	if (!((Get-WebsiteState -Name $siteAlias).Value -eq 'Stopped')) {
		Stop-WebSite -Name $siteAlias
		"Stopped web site '$siteAlias'"
	}
}

#endregion

#region Turn off Application Pool

if (Test-Path $appPoolPath) {
	if (!((Get-WebAppPoolState -Name $siteAlias).Value -eq 'Stopped')) {
		Stop-WebAppPool -Name $siteAlias
		"Stopped web application pool '$siteAlias'"
	}
}

#endregion

"Turn Off Site operation end."