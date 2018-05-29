<#
Contains method to run Unit and Integration tests. Searches either *UnitTest* or *IntegrationTest* for test dlls, so name your projects accordingly.

Currently, using NUnit to run tests.
#>

$Script:NUnitConsolePkgId = 'nunit.portable'
$Script:NUnitConsole = 'nunit3-console.exe'
$Script:PactOutputFolderName = 'pacts'
$Script:PactBrokerUriKey = 'PactBrokerUri'
$Script:PactUserNameKey = 'PactBrokerUserName'
$Script:PactPasswordKey = 'PactBrokerPassword'

function RunUnitTests([String]$targetBuildConfig)
{
    $testProjectFullNames = (Get-ChildItem . -Recurse -Include *UnitTest*.dll -Exclude *SpecFlowPlugin.dll -Name | Select-String "bin\\$targetBuildConfig")   # Find tests projects
    WriteLog "Running Unit Tests for $testProjectFullNames"

    RunTests $testProjectFullNames

    WriteLog "Unit Tests Complete"
}

function RunPactTests([String]$targetBuildConfig, [System.Collections.IDictionary]$configVariables, $addPactFileToBroker)
{
    $testProjectFullNames = (Get-ChildItem . -Recurse -Include *PactTest*.dll -Name | Select-String "bin\\$targetBuildConfig")   # Find tests projects
    WriteLog "Running Pact Tests for $testProjectFullNames"
    
    RunTests $testProjectFullNames $configVariables[$Script:PactBrokerUriKey] $configVariables[$Script:PactUserNameKey] $configVariables[$Script:PactPasswordKey] $addPactFileToBroker

    WriteLog "Pact Tests Complete"
}

function PublishPactFileToBroker($fileNames, $pactBrokerUri, $userName, $password)
{
    WriteLog "Publishing Pact Files to $pactBrokerUri"
    
    $basicAuth = "${userName}:${password}"
    $Headers = @{
        Authorization = "Basic $([System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("$basicAuth")))"
    }

    foreach ($fileName in $fileNames)
    {
        $split = $fileName.Name.Split(".")
        $split = $split[0].Split("-")
        $consumer = $split[0]
        $provider = $split[1]
        
        $pactFile = $fileName.FullName
        WriteLog "Sending file for $pactFile"
        try
        {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri "$pactBrokerUri/pacts/provider/$provider/consumer/$consumer/version/1.0.0" -Headers $Headers -Method PUT -InFile $pactFile -ContentType "application/json"
        }
        catch
        {
            if($error[0].ErrorDetails.Message -ne $null)
            {
                $message = $error[0].ErrorDetails.Message
            }
            else
            {
                $message = $error
            }
            WriteErrorAndExit "Error sending pact file to broker: $message"
        }
    }
}

function RunIntegrationTests([String]$targetBuildConfig, [System.Collections.IDictionary]$configVariables)
{
    $testProjectFullNames = (Get-ChildItem . -Recurse -Include *IntegrationTest*.dll -Exclude *SpecFlowPlugin.dll -Name | Select-String "bin\\$targetBuildConfig")   # Find tests projects
    WriteLog "Running Integration Tests for $testProjectFullNames"


    foreach ($testProjectFullName in $testProjectFullNames)
    {
        WriteLog "Processing $testProjectFullName"


        $dirName = [io.path]::GetDirectoryName($testProjectFullName)

        WriteLog "Generating config file for: $testProjectFullName"
        CreateConfigFile $configVariables $dirName
    }

    RunTests $testProjectFullNames

    WriteLog "Integration Tests Complete"
}

function RunSpecflowTests([String]$targetBuildConfig, [System.Collections.IDictionary]$configVariables)
{
    $testProjectFullNames = (Get-ChildItem . -Recurse -Include *Specflow.dll -Exclude *TechTalk.SpecFlow.dll -Name | Select-String "bin\\$targetBuildConfig")   # Find specflow projects
    WriteLog "Running Integration Tests for $testProjectFullNames"


    foreach ($testProjectFullName in $testProjectFullNames)
    {
        WriteLog "Processing $testProjectFullName"


        $dirName = [io.path]::GetDirectoryName($testProjectFullName)

        WriteLog "Generating config file for: $testProjectFullName"
        CreateConfigFile $configVariables $dirName
    }

    RunTestsForSpecFlow $testProjectFullNames

    WriteLog "Specflow Tests Complete"
}

function RunTests($testProjectFullNames, [String]$pactBrokerUri, [String]$userName, [String]$password, $addPactFileToBroker)
{
    foreach ($testProjectFullName in $testProjectFullNames)
    {
        WriteLog "Processing $testProjectFullName"

        $outputFileName = [io.path]::GetFileNameWithoutExtension($testProjectFullName) + '.xml'
        $dirName = [io.path]::GetDirectoryName($testProjectFullName)
        $nunitConsoleArgs = "`"$testProjectFullName`"", "--work", "`"$dirName`"", "`"--result:$outputFileName;format=nunit3`""
        WriteLog "Executing NUnit with args: $nunitConsoleArgs"
        dotnet vstest $testProjectFullName

        if ($LastExitCode -ne 0)
        {
            WriteErrorAndExit "$testProjectFullName - FAILED WITH EXIT CODE $LastExitCode"
        }

        if ($addPactFileToBroker)
        {
            $pactFiles = (Get-ChildItem -Path "$dirName\\$Script:PactOutputFolderName" -Recurse -Include *.json)
            PublishPactFileToBroker $pactFiles $pactBrokerUri $userName $password
        }
    }
}

function RunTestsForSpecFlow($testProjectFullNames, $testType)
{
    foreach ($testProjectFullName in $testProjectFullNames)
    {
        WriteLog "Processing $testProjectFullName"

        $outputFileName = [io.path]::GetFileNameWithoutExtension($testProjectFullName) + '.xml'
        $dirName = [io.path]::GetDirectoryName($testProjectFullName)
        $nunitConsoleArgs = "`"$testProjectFullName`"", "--work", "`"$dirName`"", "`"--result:$outputFileName;format=nunit3`""
        WriteLog "Executing NUnit with args: $nunitConsoleArgs"
        & $Script:NUnitConsole $nunitConsoleArgs

        if ($LastExitCode -ne 0)
        {
            WriteErrorAndExit "$testProjectFullName - FAILED WITH EXIT CODE $LastExitCode"
        }
    }
}

function InstallNUnit()
{
    WriteLog "Installing NUnit"
    Invoke-Expression "choco upgrade $Script:NUnitConsolePkgId -y"
}

function CreateConfigFile([System.Collections.IDictionary]$configDictionary, [String]$workingDirectory)
{
    $toolsDir         = Split-Path -Path $script:MyInvocation.MyCommand.Path
    $t4ConfigModuleName = 'ProcessT4Config.psm1'
    $t4ConfigModuleUrl  = "https://s3.amazonaws.com/aws-mdsol-dotnet-build/scripts/$t4ConfigModuleName"
    $t4ConfigModulePath = Join-Path -Path $toolsDir -ChildPath $t4ConfigModuleName
    $workingDirectory = Join-Path $toolsDir $workingDirectory

    Invoke-WebRequest -Uri $t4ConfigModuleUrl -OutFile $t4ConfigModulePath
    Import-Module $t4ConfigModulePath -Force
    ProcessT4Config\Invoke-ProcessConfigs -configVariables $configDictionary -workingDirectory $workingDirectory

}