<#

.SYNOPSIS
	Deletes other WebSites

.DESCRIPTION
	This script deletes other Websites

.PARAMETER
	The alias name of the website which will be excluded in this operation

.EXAMPLE
	Delete-Other-Sites -siteAlias "New Site"

	This example deletes other sites that does not have the parameter values as properties

#>

param(
	[Parameter(Mandatory=$true, HelpMessage="The alias name of the website which will be excluded in this operation")]
	[ValidateNotNullorEmpty()]
	[string]$siteAlias
)

"Deleting Sites other than '$siteAlias'...."

foreach ($site in Get-Website | Where { !($_.Name -eq $siteAlias)}) {
	"Deleting site ....."
	$site.Name
	Remove-WebSite -Name $site.Name
}

#endregion

"Deleting Sites operation end."