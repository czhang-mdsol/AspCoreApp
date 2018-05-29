<#

.SYNOPSIS
	Creates a backup copy from a source directory to a created directory in a destination fodler

.DESCRIPTION
	This script copies all contents from a given directory to a newly created directory

.PARAMETER source
	Specifies source directory.

.PARAMETER destinationRootFolder
	Specifies desitnation root directory.

.EXAMPLE
	Backup-Directory.ps1 -source "C:/a" -destinationRootFolder "C:/z"

	This example copies all contents of C:/a to C:/z/{newlycreatedfolder}/

#>

param(
	[Parameter(Mandatory=$true, HelpMessage="source directory")]
	[ValidateNotNullorEmpty()]
	[string]$source,

	[Parameter(Mandatory=$true, HelpMessage="desitnation root directory")]
	[ValidateNotNullorEmpty()]
	[string]$destinationRootFolder
)

"Creating Backup for '$source'...."

$timestamp = Get-Date -Format o | foreach {$_ -replace ":", "."}
$backupDirectory = "$destinationRootFolder\z$timestamp"
New-Item -ItemType directory -Path $backupDirectory
Copy-Item $source\* $backupDirectory -recurse

"Backup process end."