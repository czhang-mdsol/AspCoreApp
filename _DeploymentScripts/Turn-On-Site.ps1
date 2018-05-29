<#

.SYNOPSIS
	Turn on WebSite and Application Pool

.DESCRIPTION
	This script turns on the specified IIS website and app pool

.PARAMETER siteAlias
	Specifies the Web Site and application pool name in the IIS configuration.

.EXAMPLE
	Turn-On-Site -siteAlias "Site X"

	This example turns on the website and application pool with the name "Site X"

#>

param(
	[Parameter(Mandatory=$true, HelpMessage="An alias name for the website which will be registered in IIS")]
	[ValidateNotNullorEmpty()]
	[string]$siteAlias
)

"Turning On Site '$siteAlias'...."

#region Turn on Application Pool

if (!((Get-WebAppPoolState -Name $siteAlias).Value -eq 'Started')) {
	Start-WebAppPool -Name $siteAlias
	"Started web application pool '$siteAlias'"
}

#endregion

#region Turn on web site

if (!((Get-WebsiteState -Name $siteAlias).Value -eq 'Started')) {
	Start-WebSite -Name $siteAlias
	"Started web site '$siteAlias'"
}

#endregion

"Turn On Site operation end."