function Find-DLPLabelAutoLabelRule {
    <#
        .SYNOPSIS
            Finds auto-labeling rules that reference a sensitivity-label GUID.

        .DESCRIPTION
            Searches auto-labeling rule actions for the supplied GUID, retrieves each
            matching rule's parent policy, and identifies simulation or test modes.

            .PARAMETER LabelGuid
            The sensitivity-label GUID to locate.

            .PARAMETER LogPath
            The path used to record findings and errors.

        .OUTPUTS
            PSCustomObject containing Rules and Error. Each matching rule receives a
            ParentPolicyDetails note property.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [guid]$LabelGuid,

        [Parameter(Mandatory)]
        [string]$LogPath
    )

    Write-ToLogFile -StringObject ("`n==================== " + ('2. Auto-labeling rules (enabled and disabled)') + " ====================") -LogFile $LogPath -ForegroundColor Cyan
    Write-ToLogFile -StringObject ("  [INFO]    " + ("Searching auto-labeling rules for $LabelGuid.")) -LogFile $LogPath -LogOnly

    try {
        $rules = @(
            Get-AutoSensitivityLabelRule -ErrorAction Stop |
                Where-Object {
                    [string]$_.ApplySensitivityLabel -match [regex]::Escape([string]$LabelGuid) -or
                    [string]$_.RemoveSensitivityLabel -match [regex]::Escape([string]$LabelGuid)
                }
        )

        foreach ($rule in $rules) {
            $policy = $null
            Write-ToLogFile -StringObject ("  [FOUND]   " + ("Rule '$($rule.Name)' (Policy: $($rule.Policy)) references this GUID. Disabled: $($rule.Disabled).")) -LogFile $LogPath -ForegroundColor Green
            try {
                $policy = Get-AutoSensitivityLabelPolicy -Identity $rule.Policy -ErrorAction Stop
                Write-ToLogFile -StringObject ("  [INFO]    " + ("Parent policy '$($rule.Policy)' has Mode '$($policy.Mode)' and Enabled '$($policy.Enabled)'.")) -LogFile $LogPath -ForegroundColor Gray
                if ([string]$policy.Mode -match 'TestWithout|TestWith|Simulation') {
                    Write-ToLogFile -StringObject ("  [PARTIAL] " + ("Parent policy '$($rule.Policy)' is in simulation or test mode; the label may only have been predicted.")) -LogFile $LogPath -ForegroundColor Yellow
                }
            }
            catch {
                Write-ToLogFile -StringObject ("  [PARTIAL] " + ("Could not query parent policy '$($rule.Policy)': $($_.Exception.Message)")) -LogFile $LogPath -ForegroundColor Yellow
            }
            Add-Member -InputObject $rule -NotePropertyName ParentPolicyDetails -NotePropertyValue $policy -Force
        }

        if ($rules.Count -eq 0) {
            Write-ToLogFile -StringObject ("  [NOTHING] " + ('No auto-labeling rule currently references this GUID.')) -LogFile $LogPath -ForegroundColor Red
        }

        [pscustomobject]@{
            Rules = $rules
            Error = $null
        }
    }
    catch {
        $message = "Could not query auto-labeling rules: $($_.Exception.Message)"
        Write-ToLogFile -StringObject ("  [PARTIAL] " + ($message)) -LogFile $LogPath -ForegroundColor Yellow
        [pscustomobject]@{
            Rules = @()
            Error = $message
        }
    }
}
