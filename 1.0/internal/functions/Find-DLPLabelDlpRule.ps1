function Find-DLPLabelDlpRule {
    <#
        .SYNOPSIS
            Finds DLP compliance rules that reference a sensitivity-label GUID.

        .DESCRIPTION
            Searches ContentContainsSensitiveInformation and ApplySensitivityLabel
            values across DLP compliance rules for the supplied GUID.

            .PARAMETER LabelGuid
            The sensitivity-label GUID to locate.

            .PARAMETER LogPath
            The path used to record findings and errors.

        .OUTPUTS
            PSCustomObject containing Rules and Error.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [guid]$LabelGuid,

        [Parameter(Mandatory)]
        [string]$LogPath
    )

    Write-ToLogFile -StringObject ("`n==================== " + ('3. DLP compliance rules') + " ====================") -LogFile $LogPath -ForegroundColor Cyan
    Write-ToLogFile -StringObject ("  [INFO]    " + ("Searching DLP compliance rules for $LabelGuid.")) -LogFile $LogPath -LogOnly

    try {
        $rules = @(
            Get-DlpComplianceRule -ErrorAction Stop |
                Where-Object {
                    [string]$_.ContentContainsSensitiveInformation -match [regex]::Escape([string]$LabelGuid) -or
                    [string]$_.ApplySensitivityLabel -match [regex]::Escape([string]$LabelGuid)
                }
        )

        foreach ($rule in $rules) {
            Write-ToLogFile -StringObject ("  [FOUND]   " + ("DLP rule '$($rule.Name)' (Policy: $($rule.ParentPolicyName)) references this GUID.")) -LogFile $LogPath -ForegroundColor Green
        }
        if ($rules.Count -eq 0) {
            Write-ToLogFile -StringObject ("  [NOTHING] " + ('No DLP rule currently references this GUID.')) -LogFile $LogPath -ForegroundColor Red
        }

        [pscustomobject]@{
            Rules = $rules
            Error = $null
        }
    }
    catch {
        $message = "Could not query DLP rules: $($_.Exception.Message)"
        Write-ToLogFile -StringObject ("  [PARTIAL] " + ($message)) -LogFile $LogPath -ForegroundColor Yellow
        [pscustomobject]@{
            Rules = @()
            Error = $message
        }
    }
}
