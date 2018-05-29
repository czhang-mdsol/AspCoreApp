
$global:_BookEnd = "******************************************************************************************************"

function GetDateTime
{
    "$($(Get-Date).ToString("ddd dd-MMM-yyyy hh:mm:ss tt"))";
}

function WriteLog
{
    param([parameter(Mandatory = $true)] [String] $logMessage)

    process
    {
        Write-Host `n`n$global:_BookEnd -BackGroundColor DarkGray -ForeGroundColor Green
        Write-Host $(GetDateTime)       -BackGroundColor DarkGray -ForeGroundColor Green
        Write-Host $logMessage          -BackGroundColor DarkGray -ForeGroundColor Green
        Write-Host $global:_BookEnd     -BackGroundColor DarkGray -ForeGroundColor Green
    }
}

function WriteErrorAndExit
{
    param([parameter(Mandatory = $true)] [String] $errorMessage)

    process
    {
        Write-Host `n`n$global:_BookEnd -BackGroundColor DarkGray -ForeGroundColor Red
        Write-Host $(GetDateTime)       -BackGroundColor DarkGray -ForeGroundColor Red
        Write-Host $errorMessage        -BackGroundColor DarkGray -ForeGroundColor Red
        Write-Host $global:_BookEnd     -BackGroundColor DarkGray -ForeGroundColor Red

        Exit 1
    }
}

function CheckLastErrorCode
{
    param([parameter(Mandatory = $true)] [string] $errorMessage)

    process
    {
        if ($LastExitCode -ne 0 -or $? -eq $false)
        {
            WriteErrorAndExit "Exit Code = $LastExitCode`nFailure   = $?`n$errorMessage";
        }
    }
}

function RunCommandWithLogging
{
    param ([parameter(Mandatory = $true)] [string] $command)

    process
    {
        WriteLog "User Name:         $Env:UserName`nUser Domain:       $Env:UserDomain`nMachine Name:      $Env:ComputerName`nCurrent Directory: $PWD`nRUNNING:`n    $command";
        Invoke-Expression $command;
        CheckLastErrorCode "FAILED:`n    $command";
        WriteLog "COMPLETED:`n    $command`nExit Code = $LastExitCode`nSuccess   = $?";
    }
}
