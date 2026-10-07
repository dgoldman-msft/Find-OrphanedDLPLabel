function Get-DLPLabelCatalogEntry {
    <#
        .SYNOPSIS
            Retrieves a sensitivity label from the current Purview label catalog.

        .DESCRIPTION
            Queries Get-Label and selects the first label whose Guid exactly matches
            the supplied sensitivity-label GUID.

            .PARAMETER LabelGuid
            The sensitivity-label GUID to locate.

            .PARAMETER LogPath
            The path used to record findings and errors.

        .OUTPUTS
            PSCustomObject containing Succeeded, Label, and Error.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [guid]$LabelGuid,

        [Parameter(Mandatory)]
        [string]$LogPath
    )

    Write-ToLogFile -StringObject ("`n==================== " + ('1. Current label catalog (Get-Label)') + " ====================") -LogFile $LogPath -ForegroundColor Cyan
    Write-ToLogFile -StringObject ("  [INFO]    " + ("Querying the label catalog for $LabelGuid.")) -LogFile $LogPath -LogOnly

    try {
        $label = Get-Label -ErrorAction Stop |
            Where-Object { [string]$_.Guid -eq [string]$LabelGuid } |
            Select-Object -First 1

        if ($label) {
            Write-ToLogFile -StringObject ("  [FOUND]   " + ("Label exists: '$($label.DisplayName)' (Guid: $($label.Guid), Disabled: $($label.Disabled)).")) -LogFile $LogPath -ForegroundColor Green
        }
        else {
            Write-ToLogFile -StringObject ("  [NOTHING] " + ("GUID '$LabelGuid' was not found in the current label catalog.")) -LogFile $LogPath -ForegroundColor Red
        }

        [pscustomobject]@{
            Succeeded = $true
            Label     = $label
            Error     = $null
        }
    }
    catch {
        $message = "Could not query labels: $($_.Exception.Message)"
        Write-ToLogFile -StringObject ("  [PARTIAL] " + ($message)) -LogFile $LogPath -ForegroundColor Yellow
        [pscustomobject]@{
            Succeeded = $false
            Label     = $null
            Error     = $message
        }
    }
}
