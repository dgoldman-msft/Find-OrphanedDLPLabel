function Connect-DLPLabelComplianceSession {
    <#
        .SYNOPSIS
            Connects to Exchange Online and Security & Compliance PowerShell.

        .DESCRIPTION
            Installs ExchangeOnlineManagement for the current user when it is missing,
            imports the module, and reuses active Exchange Online and IPPS connections.
            Only missing connections are opened, and both are verified before returning.

            .PARAMETER UserPrincipalName
            The optional account used by Connect-ExchangeOnline and Connect-IPPSSession.

            .PARAMETER LogPath
            The path used to record module and connection activity.

        .NOTES
            Throws when module installation or import fails, a connection cannot be
            established or verified, or Get-Label is unavailable after connecting.
    #>

    [CmdletBinding()]
    param(
        [string]$UserPrincipalName,

        [Parameter(Mandatory)]
        [string]$LogPath
    )

    Write-ToLogFile -StringObject ("`n==================== " + ('Connecting to Exchange Online and Security & Compliance PowerShell') + " ====================") -LogFile $LogPath -ForegroundColor Cyan

    $moduleName = 'ExchangeOnlineManagement'
    $installedModule = Get-Module -Name $moduleName -ListAvailable |
        Sort-Object -Property Version -Descending |
        Select-Object -First 1

    if (-not $installedModule) {
        Write-ToLogFile -StringObject ("  [INFO]    " + ("The $moduleName module is not installed. Installing it for the current user.")) -LogFile $LogPath -ForegroundColor Gray
        try {
            Install-Module -Name $moduleName -Repository PSGallery -Scope CurrentUser -Force -AllowClobber -Confirm:$false -ErrorAction Stop
            $installedModule = Get-Module -Name $moduleName -ListAvailable |
                Sort-Object -Property Version -Descending |
                Select-Object -First 1
            if (-not $installedModule) {
                throw "Installation completed without making the $moduleName module available."
            }
            Write-ToLogFile -StringObject ("  [INFO]    " + ("Installed $moduleName version $($installedModule.Version).")) -LogFile $LogPath -ForegroundColor Gray
        }
        catch {
            $message = "Could not install the $moduleName module: $($_.Exception.Message)"
            Write-ToLogFile -StringObject ("  [NOTHING] " + ($message)) -LogFile $LogPath -ForegroundColor Red
            throw $message
        }
    }

    try {
        Import-Module -Name $moduleName -ErrorAction Stop
        Write-ToLogFile -StringObject ("  [INFO]    " + ("Imported $moduleName version $($installedModule.Version).")) -LogFile $LogPath -ForegroundColor Gray
    }
    catch {
        $message = "Could not import the $moduleName module: $($_.Exception.Message)"
        Write-ToLogFile -StringObject ("  [NOTHING] " + ($message)) -LogFile $LogPath -ForegroundColor Red
        throw $message
    }

    foreach ($commandName in 'Connect-ExchangeOnline', 'Connect-IPPSSession', 'Get-ConnectionInformation') {
        if (-not (Get-Command -Name $commandName -ErrorAction SilentlyContinue)) {
            $message = "$commandName is unavailable after importing the $moduleName module."
            Write-ToLogFile -StringObject ("  [NOTHING] " + ($message)) -LogFile $LogPath -ForegroundColor Red
            throw $message
        }
    }

    function Test-DLPLabelConnection {
        param(
            [Parameter(Mandatory)]
            [ValidateSet('ExchangeOnline', 'IPPSSession')]
            [string]$ConnectionType
        )

        $uriPattern = if ($ConnectionType -eq 'ExchangeOnline') {
            'outlook\.office365\.com'
        }
        else {
            'ps\.compliance\.protection\.outlook\.com'
        }

        $connection = @(
            Get-ConnectionInformation -ErrorAction Stop |
                Where-Object {
                    $_.State -eq 'Connected' -and
                    [string]$_.ConnectionUri -match $uriPattern
                }
        )
        if ($connection.Count -gt 0) {
            return $true
        }

        $legacySession = @(
            Get-PSSession -ErrorAction SilentlyContinue |
                Where-Object {
                    $_.State -eq 'Opened' -and
                    (
                        [string]$_.ComputerName -match $uriPattern -or
                        [string]$_.ConnectionUri -match $uriPattern
                    )
                }
        )

        return $legacySession.Count -gt 0
    }

    $connectionParameters = @{
        ShowBanner  = $false
        ErrorAction = 'Stop'
    }
    if ($UserPrincipalName) {
        $connectionParameters.UserPrincipalName = $UserPrincipalName
    }

    try {
        if (Test-DLPLabelConnection -ConnectionType ExchangeOnline) {
            Write-ToLogFile -StringObject ("  [INFO]    " + ('Reusing the existing Exchange Online connection.')) -LogFile $LogPath -ForegroundColor Gray
        }
        else {
            Write-ToLogFile -StringObject ("  [INFO]    " + ('No active Exchange Online connection was found; opening one.')) -LogFile $LogPath -ForegroundColor Gray
            Connect-ExchangeOnline @connectionParameters | Out-Null
            if (-not (Test-DLPLabelConnection -ConnectionType ExchangeOnline)) {
                throw 'Connect-ExchangeOnline completed, but an active Exchange Online connection could not be verified.'
            }
            Write-ToLogFile -StringObject ("  [INFO]    " + ('Connected to Exchange Online successfully.')) -LogFile $LogPath -ForegroundColor Gray
        }

        if (Test-DLPLabelConnection -ConnectionType IPPSSession) {
            Write-ToLogFile -StringObject ("  [INFO]    " + ('Reusing the existing Security & Compliance PowerShell connection.')) -LogFile $LogPath -ForegroundColor Gray
        }
        else {
            Write-ToLogFile -StringObject ("  [INFO]    " + ('No active Security & Compliance PowerShell connection was found; opening one.')) -LogFile $LogPath -ForegroundColor Gray
            Connect-IPPSSession @connectionParameters | Out-Null
            if (-not (Test-DLPLabelConnection -ConnectionType IPPSSession)) {
                throw 'Connect-IPPSSession completed, but an active Security & Compliance PowerShell connection could not be verified.'
            }
            Write-ToLogFile -StringObject ("  [INFO]    " + ('Connected to Security & Compliance PowerShell successfully.')) -LogFile $LogPath -ForegroundColor Gray
        }

        if (-not (Get-Command -Name Get-Label -ErrorAction SilentlyContinue)) {
            throw 'Both connections are active, but Get-Label is unavailable.'
        }
    }
    catch {
        Write-ToLogFile -StringObject ("  [NOTHING] " + ("Connection failed: $($_.Exception.Message)")) -LogFile $LogPath -ForegroundColor Red
        throw
    }
}
