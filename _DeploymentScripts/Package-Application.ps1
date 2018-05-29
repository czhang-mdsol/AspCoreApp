<#

.SYNOPSIS
    Creates a web deployment package with necessary deploy scripts

.DESCRIPTION
    This package creates a web deployment package with necessary deploy scripts

.PARAMETER projectFileName

.EXAMPLE
    Package-Application.ps1 -projectFileName "Medidata.MedsExtractor.UI" -packageOutput

    This example creates a web deployment package \meds_extractor\artifacts
#>

param(
    [Parameter(Mandatory=$true, HelpMessage="project name")]
    [string]$projectFileName,

    [Parameter(Mandatory=$false, HelpMessage="package file name")]
    [string]$packageFileName,

    [parameter(Mandatory = $false)] [switch] $packageOutput,

    [parameter(Mandatory = $false)] [switch] $skipTests
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\RunTests.ps1"
. "$PSScriptRoot\LogUtility.ps1"

Set-Location $PSScriptRoot   # from the location of this script
Set-Location ..              # move to the root of the repository
$repositoryRoot = $PWD

$deploymentScriptsLocation = "$PWD\_DeploymentScripts";
$artifactsDirectory = "$PWD\artifacts";
$projectFullPath = Get-Childitem -Include "$projectFileName.csproj" -Recurse

if ([string]::IsNullOrEmpty($packageFileName))
{
    $packageFileName = "mex-ui.$env:BUILD_NUMBER.$env:GIT_COMMIT.zip";
}

if (!(Test-Path $projectFullPath))
{
    WriteErrorAndExit "Project file '$projectFileName' not found"
}

$projectDirectory = Split-Path $projectFullPath

WriteLog "Cleaning Project '$projectFullPath'"
dotnet clean $projectFullPath --configuration Release --verbosity m
WriteLog "Cleaning Complete '$projectFullPath'"

WriteLog "Restoring Project '$projectFullPath'"
dotnet restore $projectFullPath --verbosity m
WriteLog "Restoring Complete '$projectFullPath'"

WriteLog "Building Project '$projectFullPath'"
dotnet build $projectFullPath --configuration Release
WriteLog "Building Complete '$projectFullPath'"

if (-not $skipTests)
{
    InstallNUnit
    RunUnitTests "DEBUG"
    RunIntegrationTests "DEBUG"
}

if ($packageOutput)
{
    if (Test-Path $artifactsDirectory)
    {
        WriteLog "Deleting old files if existing from '$artifactsDirectory'"
        Remove-Item -recurse -Force $artifactsDirectory\*
    }

    Set-Location $projectDirectory

    WriteLog "npm install $projectDirectory"
    npm install
    WriteLog "npm install Complete"

    WriteLog "npm run build $projectDirectory"
    npm run build
    WriteLog "npm run build Complete"

    WriteLog "Copying artifacts to '$artifactsDirectory'"
    Copy-Item $projectDirectory\node_modules $artifactsDirectory\$projectFileName\node_modules -recurse
    Copy-Item $projectDirectory\wwwroot $artifactsDirectory\$projectFileName\wwwroot -recurse
    Copy-Item "$projectDirectory\bin\release\netcoreapp2.0" "$artifactsDirectory\$projectFileName\netcoreapp2.0" -recurse
    WriteLog "Copy Complete"

    cd $deploymentScriptsLocation

    WriteLog "Publishing project '$projectDirectory' to $artifactsDirectory\$projectFileName"
    dotnet publish $projectDirectory --configuration Release --output "$artifactsDirectory\$projectFileName" --verbosity m -r win-x64

    WriteLog "Copying deployment scripts from '$deploymentScriptsLocation' to $artifactsDirectory"
    Copy-Item $deploymentScriptsLocation\* $artifactsDirectory -recurse

    WriteLog "Packaging everything"
    Compress-Archive -Path $artifactsDirectory\* -DestinationPath "$artifactsDirectory\$packageFileName"

    WriteLog "Package created: $artifactsDirectory\$packageFileName"
}

Set-Location $repositoryRoot
