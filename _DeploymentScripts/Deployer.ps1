$ErrorActionPreference = "Stop";
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$applicationName = "$env:Application-$env:Environment"

#supply environment variable for application identification
[Environment]::SetEnvironmentVariable("ApplicationName", "$applicationName")
[Environment]::SetEnvironmentVariable("IIS Web Application Name", "$applicationName")
[Environment]::SetEnvironmentVariable("NewRelicAppName", "$applicationName")

#delete other sites
Invoke-Expression "$scriptDir\Delete-Other-Sites.ps1 -siteAlias '$applicationName'"

#turn off existing site and app pool
Invoke-Expression "$scriptDir\Turn-Off-Site.ps1 -siteAlias '$applicationName'"

#update configuration settings before deploying
cd $env:DeployPackageLocation
###dotnet DiceBag.dll
cd $scriptDir

#create website
if ($env:ApplicationProtocol) {
	#create website with specified protocol and port no
	Invoke-Expression "$scriptDir\Create-WebSite.ps1 -applicationDirectory '$env:ApplicationDirectory' -siteAlias '$applicationName' -protocol '$env:ApplicationProtocol' -portNo $env:ApplicationPortNo"
}
else {
	#create website on both http and https protocol with ports 80 and 443 respectively
	Invoke-Expression "$scriptDir\Create-WebSite.ps1 -applicationDirectory '$env:ApplicationDirectory' -siteAlias '$applicationName'"
}

#deploy binaries
Invoke-Expression "$scriptDir\Deploy-WebSite.ps1 -packageLocation '$env:DeployPackageLocation' -siteLocation '$env:ApplicationDirectory'"

#turn on site
Invoke-Expression "$scriptDir\Turn-On-Site.ps1 -siteAlias '$applicationName'"

#backup site director
Invoke-Expression "$scriptDir\Backup-Directory.ps1 -source $env:ApplicationDirectory -destinationRootFolder $env:ApplicationRootDirectory"

#iis reset
Invoke-Command -scriptblock {iisreset}
