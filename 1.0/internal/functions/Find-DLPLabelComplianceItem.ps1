function Find-DLPLabelComplianceItem {
    <#
        .SYNOPSIS
            Runs a Compliance Search for messages with specified subjects.

        .DESCRIPTION
            Creates and starts a Compliance Search against an Exchange location, then
            polls until it completes, fails, partially succeeds, or reaches the timeout.

            .PARAMETER ExchangeLocation
            The mailbox or Exchange location to search.

            .PARAMETER Subjects
                Optional exact message subjects combined with the OR operator.

            .PARAMETER LabelGuid
                The sensitivity-label GUID used when IncludeMessageLabelInfo is specified.

            .PARAMETER LabelName
                The sensitivity-label display name included in the returned search summary.

            .PARAMETER IncludeMessageLabelInfo
                Adds a SensitivityLabel query for LabelGuid and includes label details in
                the returned search summary.

            .PARAMETER SearchTimeoutSeconds
            The maximum number of seconds to wait for the search.

            .PARAMETER LogPath
            The path used to record search status, findings, and errors.

        .OUTPUTS
            PSCustomObject containing Search and Error.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ExchangeLocation,

        [ValidateNotNullOrEmpty()]
        [string[]]$Subjects,

        [Parameter(Mandatory)]
        [guid]$LabelGuid,

        [string]$LabelName,

        [switch]$IncludeMessageLabelInfo,

        [Parameter(Mandatory)]
        [ValidateRange(10, 3600)]
        [int]$SearchTimeoutSeconds,

        [Parameter(Mandatory)]
        [string]$LogPath
    )

    Write-ToLogFile -StringObject ("`n==================== " + ('5. Compliance Search for affected items') + " ====================") -LogFile $LogPath -ForegroundColor Cyan
    Write-ToLogFile -StringObject ("  [INFO]    " + ("Preparing a Compliance Search for $ExchangeLocation.")) -LogFile $LogPath -LogOnly

    if ($Subjects.Count -eq 0 -and -not $IncludeMessageLabelInfo) {
        throw 'Supply at least one subject or specify IncludeMessageLabelInfo.'
    }

    $searchName = "FindOrphanedDLPLabel_$((Get-Date).ToString('yyyyMMddHHmmss'))"
    $queryParts = [System.Collections.Generic.List[string]]::new()
    if ($Subjects.Count -gt 0) {
        $subjectQuery = ($Subjects | ForEach-Object {
                $escapedSubject = $_.Replace('"', '""')
                "subject:`"$escapedSubject`""
            }) -join ' OR '
        $queryParts.Add("($subjectQuery)")
    }
    if ($IncludeMessageLabelInfo) {
        $queryParts.Add("SensitivityLabel:$LabelGuid")
    }
    $query = $queryParts -join ' AND '

    try {
        New-ComplianceSearch -Name $searchName -ExchangeLocation $ExchangeLocation -ContentMatchQuery $query -ErrorAction Stop | Out-Null
        Write-ToLogFile -StringObject ("  [INFO]    " + ("Created Compliance Search '$searchName' with query: $query")) -LogFile $LogPath -ForegroundColor Gray
        Start-ComplianceSearch -Identity $searchName -ErrorAction Stop
        Write-ToLogFile -StringObject ("  [INFO]    " + ("Started Compliance Search '$searchName'.")) -LogFile $LogPath -ForegroundColor Gray

        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        do {
            Start-Sleep -Seconds 10
            $search = Get-ComplianceSearch -Identity $searchName -ErrorAction Stop
            Write-ToLogFile -StringObject ("  [INFO]    " + ("Compliance Search '$searchName' status: $($search.Status).")) -LogFile $LogPath -LogOnly
        } while ($search.Status -notin @('Completed', 'Failed', 'PartiallySucceeded') -and $stopwatch.Elapsed.TotalSeconds -lt $SearchTimeoutSeconds)
        $stopwatch.Stop()

        if ($search.Status -eq 'Completed') {
            Write-ToLogFile -StringObject ("  [FOUND]   " + ("Search completed. Items found: $($search.Items), Size: $($search.Size).")) -LogFile $LogPath -ForegroundColor Green
        }
        elseif ($search.Status -in @('Failed', 'PartiallySucceeded')) {
            Write-ToLogFile -StringObject ("  [PARTIAL] " + ("Search ended with status '$($search.Status)'.")) -LogFile $LogPath -ForegroundColor Yellow
        }
        else {
            Write-ToLogFile -StringObject ("  [PARTIAL] " + ("Search did not finish within $SearchTimeoutSeconds seconds. Current status: $($search.Status).")) -LogFile $LogPath -ForegroundColor Yellow
        }

        $searchSummary = [pscustomobject]@{
            Name             = $search.Name
            Status           = $search.Status
            Items            = $search.Items
            Size             = $search.Size
            ExchangeLocation = $ExchangeLocation
            Query            = $query
            Label            = if ($IncludeMessageLabelInfo) { $LabelName } else { $null }
            LabelGuid        = if ($IncludeMessageLabelInfo) { $LabelGuid } else { $null }
        }

        [pscustomobject]@{
            Search = $searchSummary
            Error  = $null
        }
    }
    catch {
        $message = "Compliance Search failed: $($_.Exception.Message)"
        Write-ToLogFile -StringObject ("  [NOTHING] " + ($message)) -LogFile $LogPath -ForegroundColor Red
        if ($_.Exception.Message -match 'AADSTS500011|cannot be found') {
            Write-ToLogFile -StringObject ("  [INFO]    " + ('Reconnect with Connect-IPPSSession -EnableSearchOnlySession, then retry the command.')) -LogFile $LogPath -ForegroundColor Gray
        }
        [pscustomobject]@{
            Search = $null
            Error  = $message
        }
    }
}
