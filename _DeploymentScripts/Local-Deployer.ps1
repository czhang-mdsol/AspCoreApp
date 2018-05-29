$ErrorActionPreference = "Stop";
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projDir = (Get-Item $scriptDir).parent.FullName

#environment variables
Invoke-Expression "$scriptDir\Local-Databag.ps1"

#build and publish
$projLocation = "$projDir\Medidata.MedsExtractor.UI\Medidata.MedsExtractor.UI"
$projName = "Medidata.MedsExtractor.UI";
$packageFileName = "mex-ui.$env:BUILD_NUMBER.$env:GIT_COMMIT.zip";
Invoke-Expression "$scriptDir\Package-Application.ps1 -projectFileName '$projName' -packageOutput -packageFileName '$packageFileName'"

# prepare working folder
$workDirectory = "$env:WorkDirectory"
if (Test-Path $workDirectory) { 
	Remove-Item -recurse -Force $workDirectory\*
}
else {
	New-Item $workDirectory -type directory 
}
set-alias sz "$env:7z"
sz x -aos $env:SourcePackageDirectory\$packageFileName "-o$workDirectory"

#deploy
Invoke-Expression "$scriptDir\Deployer.ps1"