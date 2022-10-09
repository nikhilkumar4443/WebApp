<#
    .SYNOPSIS
      Install UiPath Orchestrator.

    .Description
      Install UiPath Orchestrator and configure UiPath.Orchestrator.dll.config

    .PARAMETER orchestratorFolder
      String. Path where Orchestrator will be installed. Example: $orchestratorFolder = "C:\Program Files(x86)\UiPath\Orchestrator"

    .PARAMETER databaseServerName
      String. Mandatory. SQL server name. Example: $databaseServerName = "SQLServerName.local"

    .PARAMETER databaseName
      String. Mandatory. Database Name. Example: $databaseName = "devtestdb"

    .PARAMETER databaseUserName
      String. Mandatory. Database Username. Example: $databaseUserName = "devtestdbuser"

    .PARAMETER databaseUserPassword
      String. Mandatory. Database Password  Example: $databaseUserPassword = "d3vt3std@taB@s3!"

    .PARAMETER redisServerHost
      String. There is no need to use Redis if there is only one Orchestrator instance. Redis is mandatory in multi-node deployment.  Example: $redisServerHost = "redishostDNS"

    .PARAMETER nuGetStoragePath
      String. Mandatory. Storage Path where the Nuget Packages are saved. Also you can use NFS or SMB share.  Example: $nuGetStoragePath = "\\nfs-share\NugetPackages"

    .PARAMETER orchestratorAdminPassword
      String. Mandatory. Orchestrator Admin password is necessary for a new installation and to change the Nuget API keys. Example: $orchestratorAdminPassword = "P@ssW05D!"

    .PARAMETER orchestratorAdminUsername
      String. Orchestrator Admin username in order to change the Nuget API Keys.  Example: $orchestratorAdminUsername = "admin"

    .INPUTS
      Parameters above.

    .OUTPUTS
      None

    .Example
      powershell.exe -ExecutionPolicy Bypass -File "\\fileLocation\Install-UiPathOrchestrator.ps1" -databaseServerName  "SQLServerName.local"  -databaseName "devtestdb"  -databaseUserName "devtestdbuser" -databaseUserPassword "d3vt3std@taB@s3!" -orchestratorAdminPassword "P@ssW05D!" -redisServerHost "redishostDNS" -NuGetStoragePath "\\nfs-share\NugetPackages"
#>
[CmdletBinding()]

param(

    [Parameter()]
    [ValidateSet('OrchestratorFeature, IdentityFeature')]
    [Array] $msiFeatures = ('OrchestratorFeature', 'IdentityFeature'),

    [Parameter(Mandatory = $true)]
    [string]  $databaseServerName,

    [Parameter(Mandatory = $true)]
    [string]  $databaseName,

    [Parameter(Mandatory = $true)]
    [string]  $databaseUserName,

    [Parameter(Mandatory = $true)]
    [string]  $databaseUserPassword,

    [Parameter()]
    [string[]] $redisServerHost,

    [Parameter()]
    [string] $redisServerPort,

    [Parameter()]
    [string] $redisServerPassword,

    [Parameter(Mandatory = $true)]
    [string] $nuGetStoragePath,

    [Parameter()]
    [string] $orchestratorAdminUsername = "admin",

    [Parameter(Mandatory = $true)]
    [string] $orchestratorAdminPassword,

    [Parameter(Mandatory=$false)]
    [AllowEmptyString()]
    [string] $orchestratorLicenseCode,

    [Parameter()]
    [string] $configTableName,

    [Parameter()]
    [string] $configS3BucketName,

    [Parameter()]
    [ValidateScript( { if (($_ -as [System.URI]).AbsoluteURI -eq $null) { throw "Invalid" } return $true })]
    [string] $publicUrl


)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$ErrorActionPreference = "Stop"
[System.String]$rootDirectory = "C:\workdir"
[System.String]$installLog = Join-Path -Path $script:rootDirectory -ChildPath "log\install.log"
[System.String]$orchestratorHost = ([System.URI]$publicUrl).Host
[System.String]$orchestratorTenant = "host"

function Main {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    RemoveIISDirectoryBrowsingFeature

    $msiProperties = Get-OrchestratorMsiProperties

    Install-UiPathOrchestratorEnterprise -msiPath "$rootDirectory\sources\UiPathOrchestrator.msi" -logPath $script:installLog -msiFeatures $msiFeatures -msiProperties $msiProperties

    Remove-WebSite -webSiteName "Default Web Site" -port "80"
}

function RemoveIISDirectoryBrowsingFeature {
    try {
        $checkFeature = Get-WindowsFeature "IIS-DirectoryBrowsing"
        if ($checkFeature.Installed -eq $true) {
            Disable-WindowsOptionalFeature -FeatureName IIS-DirectoryBrowsing -Remove -NoRestart -Online
            Write-Verbose "Feature IIS-DirectoryBrowsing is removed"
        }
    }
    catch {
        Write-Error -Exception $_.Exception -Message "Failed to remove feature IIS-DirectoryBrowsing"
        throw $_.Exception
    }
}

function Restart-OrchestratorSite {
param(
        [string] $siteName = "UiPath Orchestrator"
)

    try {
        if (-not $(Get-WebBinding -Name "UiPath Orchestrator")){
            New-WebBinding -Name $siteName -IPAddress "*" -Port 443 -Protocol "https"
        }
        Stop-Website -Name $siteName
        Start-Website -Name $siteName
        Write-Verbose "Adding new binding and restarting Orchestrator WebSite !"
    }
    catch {
        Write-Error -Exception $_.Exception -Message "Failed to configure Orchestrator"
        throw $_.Exception
    }
}


function Get-OrchestratorMsiProperties {
    if (Test-Path "$rootDirectory\config.json") {
        $msiProperties = @{
            "PARAMETERS_FILE" = "$rootDirectory\config.json"
            "SECONDARY_NODE"  = "1"
            "WEBSITE_HOST"    = $orchestratorHost
        }
    }
    else {
        $msiProperties += @{
            "DB_SERVER_NAME"              = "$databaseServerName";
            "DB_DATABASE_NAME"            = "$databaseName";
            "HOSTADMIN_PASSWORD"          = "$orchestratorAdminPassword";
            "DEFAULTTENANTADMIN_PASSWORD" = "$orchestratorAdminPassword";
            "TELEMETRY_ENABLED"           = "1";
        }

        $msiProperties += @{ "APPPOOL_IDENTITY_TYPE" = "APPPOOLIDENTITY"; }

        $msiProperties += @{
            "DB_AUTHENTICATION_MODE" = "SQL";
            "DB_USER_NAME"           = "$databaseUserName";
            "DB_PASSWORD"            = "$databaseUserPassword";
        }

        $msiProperties += @{
            "CERTIFICATE_SUBJECT"    = $orchestratorHost
            "IS_CERTIFICATE_SUBJECT" = $orchestratorHost
        }

        $msiProperties += @{
            "OUTPUT_PARAMETERS_FILE" = "$rootDirectory\config.json";
            "PUBLIC_URL"             = "$publicUrl"
            "WEBSITE_HOST"           = $orchestratorHost
        }

        $msiProperties += @{
            "REDIS_HOST"     = $redisServerHost -join ','
            "REDIS_PORT"     = $redisServerPort
            "REDIS_PASSWORD" = $redisServerPassword
        }

        $msiProperties += @{
            "STORAGE_TYPE"     = "FileSystem"
            "STORAGE_LOCATION" = "RootPath=\\$nuGetStoragePath"
        }
    }
    return $msiProperties
}

function Install-UiPathOrchestratorEnterprise {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $msiPath,
        [string] $logPath,
        [Parameter(Mandatory = $true)]
        [string[]] $msiFeatures,
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable] $msiProperties
    )

    Write-Verbose "Installing UiPath"

    if (!(Test-Path $msiPath)) {
        throw "No .msi file found at path '$msiPath'"
    }

    $msiExecArgs = "/i `"$msiPath`" /q /l*vx `"$logPath`" "

    $msiExecArgs += "ADDLOCAL=`"$( $msiFeatures -join ',' )`" "
    $msiExecArgs += (($msiProperties.GetEnumerator() | ForEach-Object { "$( $_.Key )=$( $_.Value )" }) -join " ")

    Write-Verbose "Installing Features: $msiFeatures"
    Write-Verbose "Installing Args: $msiExecArgs"

    $tries = 3
    while ($tries -ge 1) {
        Write-Host "Starting the installation with $tries tries remaining"
        $process = Start-Process "msiexec" -ArgumentList $msiExecArgs -Wait -PassThru

        Write-Host "Process exit code: $($process.ExitCode)"
        if ($($process.ExitCode) -ne 0) {
            Write-Host "Installation failed"
            if ($($process.ExitCode) -eq 1620) {
                $tries--
                Start-Sleep 10
            } else {
                throw "Installation failed and will not be retried"
            }
        } else {
            $tries = 0
        }
    }
}

function Remove-WebSite ($webSiteName, $port) {

    try {
        $WebSiteBindingExists = Get-WebBinding -Name "$webSiteName"
        if ($WebSiteBindingExists) {
            Stop-Website "$webSiteName"
            Set-ItemProperty "IIS:\Sites\$webSiteName" serverAutoStart False
            Remove-WebBinding -Name "$webSiteName" -BindingInformation "*:${port}:"
            Write-Verbose "Removed $webSiteName WebSite !"
        }
    }
    catch {
        Write-Error -Exception $_.Exception -Message "Failed to remove website $webSiteName"
        throw $_.Exception
    }
}

function Test-OrchestratorInstallation {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript( { if (($_ -as [System.URI]).AbsoluteURI -eq $null) { throw "Invalid" } return $true })]
        [string]$Url
    )

    try {
        $ErrorActionPreference = "Stop"
        $tries = 20
        Write-Verbose "Trying to connect to Orchestrator at $Url"
        while ($tries -ge 1) {
            try {
                Invoke-WebRequest -URI $Url -Method 'GET' -TimeoutSec 180 -UseBasicParsing
                break
            }
            catch {
                $tries--
                Write-Verbose "Exception: $_"
                if ($tries -lt 1) {
                    throw $_
                }
                else {
                    Write-Verbose "Failed to GET $Url. Retrying again in 30 seconds"
                    Start-Sleep 30
                }
            }
        }

    }
    catch {
        Write-Error -Exception $_.Exception -Message "Failed to connect to installed Orchestrator at $Url"
        throw $_.Exception
    }
}

# start point 

try {
    . "$PSScriptRoot\Get-File.ps1" -Source "s3://$configS3BucketName/config.json" -Destination "$rootDirectory\config.json" -Verbose
    . "$PSScriptRoot\Get-File.ps1" -Source "s3://$configS3BucketName/$orchestratorHost.pfx" -Destination "$rootDirectory\$orchestratorHost.pfx" -Verbose
    . "$PSScriptRoot\Get-File.ps1" -Source "s3://$configS3BucketName/UiPath.Orchestrator.dll.config" -Destination "$rootDirectory\UiPath.Orchestrator.dll.config" -Verbose
}
catch {
    Write-Verbose "No file was downloaded from s3://$configS3BucketName/config.json"
}

try {
    if ((Test-Path "$rootDirectory\config.json") -and (Test-Path "$rootDirectory\$orchestratorHost.pfx") ) {
        Write-Information "Configuration already exists, performing installation as secondary node"
        . "$PSScriptRoot\Install-SelfSignedCertificate.ps1" -rootPath "$rootDirectory" -certificatePassword $orchestratorAdminPassword -orchestratorHost $orchestratorHost
        Main
        Copy-Item "$rootDirectory\UiPath.Orchestrator.dll.config" -Destination "C:\Program Files (x86)\UiPath\Orchestrator\UiPath.Orchestrator.dll.config" -Force
        Restart-OrchestratorSite
    }
    else {
        Write-Verbose "No configuration is available, performing installation for the first time"
        . "$PSScriptRoot\Install-SelfSignedCertificate.ps1" -rootPath "$rootDirectory" -certificatePassword $orchestratorAdminPassword -orchestratorHost $orchestratorHost
        Main
        Write-Verbose "Performed installation for the first time, testing installation"
        Restart-OrchestratorSite
        Test-OrchestratorInstallation -Url $publicUrl -Verbose
        Write-Verbose "Uploading the configuration"
        . "$PSScriptRoot\Write-ConfigToS3.ps1" -Source "$rootDirectory\config.json" -Destination "s3://$configS3BucketName/config.json"
        . "$PSScriptRoot\Write-ConfigToS3.ps1" -Source "C:\Program Files (x86)\UiPath\Orchestrator\UiPath.Orchestrator.dll.config" -Destination "s3://$configS3BucketName/UiPath.Orchestrator.dll.config"
        . "$PSScriptRoot\Write-ConfigToS3.ps1" -Source "$rootDirectory\$orchestratorHost.pfx" -Destination "s3://$configS3BucketName/$orchestratorHost.pfx"
    }
}
catch {
    Write-Verbose "Installation failed with $($_.Exception)"
    Write-Error -Exception $_.Exception -Message "Failed to install Orchestrator"
    throw $_.Exception
}
