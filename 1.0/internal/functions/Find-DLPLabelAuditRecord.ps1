function Find-DLPLabelAuditRecord {
    <#
        .SYNOPSIS
            Searches the Unified Audit Log for a sensitivity-label GUID.

        .DESCRIPTION
            Searches the requested audit history in date chunks and returns matching
            records whose AuditData contains the supplied GUID. Individual chunk
            failures are collected without discarding results from successful chunks.

            .PARAMETER LabelGuid
            The sensitivity-label GUID to locate.

            .PARAMETER AuditDaysBack
                The number of historical days to search. Valid values are 1 through 365.

            .PARAMETER AuditChunkDays
            The number of days included in each audit query.

            .PARAMETER ShowFullAuditDetails
                Displays complete matching audit payloads in the console. Complete payloads
                are always written to the log regardless of this switch.

            .PARAMETER LogPath
            The path used to record progress, findings, and errors.

        .OUTPUTS
            PSCustomObject containing relevant, parsed audit Records and Errors arrays.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [guid]$LabelGuid,

        [Parameter(Mandatory)]
        [ValidateRange(1, 365)]
        [int]$AuditDaysBack,

        [Parameter(Mandatory)]
        [ValidateRange(1, 365)]
        [int]$AuditChunkDays,

        [switch]$ShowFullAuditDetails,

        [Parameter(Mandatory)]
        [string]$LogPath
    )

    Write-ToLogFile -StringObject ("`n==================== " + ("4. Unified Audit Log sweep (last $AuditDaysBack days, $AuditChunkDays-day chunks)") + " ====================") -LogFile $LogPath -ForegroundColor Cyan
    Write-ToLogFile -StringObject ("  [INFO]    " + ('Use -ShowFullAuditDetails to display complete matching audit records in the console.')) -LogFile $LogPath -ForegroundColor Yellow
    Write-ToLogFile -StringObject ("  [INFO]    " + ("Searching audit records for $LabelGuid.")) -LogFile $LogPath -LogOnly

    $endDate = Get-Date
    $current = $endDate.AddDays(-$AuditDaysBack)
    $records = [System.Collections.Generic.List[object]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()

    function Find-DLPLabelAuditProperty {
        param(
            [object]$InputObject,
            [string]$Path,
            [string]$GuidText,
            [int]$Depth = 0
        )

        if ($null -eq $InputObject -or $Depth -gt 10) {
            return
        }

        if ($InputObject -is [string] -or $InputObject.GetType().IsValueType) {
            $value = [string]$InputObject
            if ($Path -and $value -match [regex]::Escape($GuidText)) {
                "$Path=$value"
            }
            return
        }

        if ($InputObject -is [System.Collections.IDictionary]) {
            foreach ($key in $InputObject.Keys) {
                $childPath = if ($Path) { "$Path.$key" } else { [string]$key }
                Find-DLPLabelAuditProperty -InputObject $InputObject[$key] -Path $childPath -GuidText $GuidText -Depth ($Depth + 1)
            }
            return
        }

        if ($InputObject -is [System.Collections.IEnumerable]) {
            $index = 0
            foreach ($item in $InputObject) {
                Find-DLPLabelAuditProperty -InputObject $item -Path "$Path[$index]" -GuidText $GuidText -Depth ($Depth + 1)
                $index++
            }
            return
        }

        foreach ($property in $InputObject.PSObject.Properties) {
            $childPath = if ($Path) { "$Path.$($property.Name)" } else { $property.Name }
            Find-DLPLabelAuditProperty -InputObject $property.Value -Path $childPath -GuidText $GuidText -Depth ($Depth + 1)
        }
    }

    while ($current -lt $endDate) {
        $chunkEnd = $current.AddDays($AuditChunkDays)
        if ($chunkEnd -gt $endDate) {
            $chunkEnd = $endDate
        }

        Write-ToLogFile -StringObject ("  [INFO]    " + ("Searching audit chunk $($current.ToString('u')) to $($chunkEnd.ToString('u')).")) -LogFile $LogPath -ForegroundColor Gray
        try {
            $chunkRecords = Search-UnifiedAuditLog -StartDate $current -EndDate $chunkEnd -ResultSize 5000 -ErrorAction Stop |
                Where-Object { [string]$_.AuditData -match [regex]::Escape([string]$LabelGuid) }
            foreach ($record in $chunkRecords) {
                try {
                    $data = $record.AuditData | ConvertFrom-Json -Depth 100 -ErrorAction Stop
                    $matchingProperties = @(
                        Find-DLPLabelAuditProperty -InputObject $data -Path '' -GuidText ([string]$LabelGuid) |
                            Select-Object -Unique
                    )
                    $subject = if ($data.Subject) {
                        $data.Subject
                    }
                    elseif ($data.Item -and $data.Item.Subject) {
                        $data.Item.Subject
                    }
                    else {
                        $null
                    }

                    $recordProperties = [ordered]@{
                        PSTypeName    = 'Find.OrphanedDLPLabel.AuditRecord'
                        CreationTime  = $data.CreationTime
                        Operation     = $data.Operation
                        UserId        = $data.UserId
                        Workload      = $data.Workload
                        Subject       = $subject
                        ObjectId      = $data.ObjectId
                        FileName      = $data.SourceFileName
                        LabelGuid     = $LabelGuid
                        LabelEvidence = $matchingProperties
                    }
                    $auditRecord = [pscustomobject]$recordProperties
                    $auditRecord | Add-Member -MemberType ScriptMethod -Name ToString -Value {
                        $target = if ($this.Subject) {
                            @('Subject', $this.Subject)
                        }
                        elseif ($this.FileName) {
                            @('FileName', $this.FileName)
                        }
                        elseif ($this.ObjectId) {
                            @('ObjectId', $this.ObjectId)
                        }
                        else {
                            @('Target', 'Unavailable')
                        }
                        $lines = [System.Collections.Generic.List[string]]::new()
                        $lines.Add('')
                        $lines.Add("CreationTime: $($this.CreationTime)")
                        $lines.Add("Operation: $($this.Operation)")
                        $lines.Add("UserId: $($this.UserId)")
                        $lines.Add("Workload: $($this.Workload)")
                        $lines.Add("$($target[0]): $($target[1])")
                        $lines.Add("LabelGuid: $($this.LabelGuid)")
                        foreach ($evidence in $this.LabelEvidence) {
                            $lines.Add("LabelEvidence: $evidence")
                        }
                        $lines.Add('')
                        return $lines -join [Environment]::NewLine
                    } -Force
                    $records.Add($auditRecord)

                    $fullAuditDataJson = $data | ConvertTo-Json -Depth 100 -Compress
                    Write-ToLogFile -StringObject ("  [FOUND]   " + ($fullAuditDataJson)) -LogFile $LogPath -ForegroundColor Green -LogOnly:(-not $ShowFullAuditDetails)
                }
                catch {
                    $message = "An audit record matched but its AuditData could not be parsed: $($_.Exception.Message)"
                    $errors.Add($message)
                    Write-ToLogFile -StringObject ("  [PARTIAL] " + ($message)) -LogFile $LogPath -ForegroundColor Yellow
                }
            }
        }
        catch {
            $message = "Audit chunk $($current.ToString('yyyy-MM-dd')) to $($chunkEnd.ToString('yyyy-MM-dd')) failed: $($_.Exception.Message)"
            $errors.Add($message)
            Write-ToLogFile -StringObject ("  [PARTIAL] " + ($message)) -LogFile $LogPath -ForegroundColor Yellow
        }
        $current = $chunkEnd
    }
    if ($records.Count -gt 0) {
        Write-ToLogFile -StringObject ("  [FOUND]   " + ("$($records.Count) audit record(s) reference this GUID.")) -LogFile $LogPath -ForegroundColor Green -LogOnly:(-not $ShowFullAuditDetails)
    }
    else {
        Write-ToLogFile -StringObject ("  [NOTHING] " + ("Zero audit log records reference this GUID across $AuditDaysBack days.")) -LogFile $LogPath -ForegroundColor Red
    }

    [pscustomobject]@{
        Records = $records.ToArray()
        Errors  = $errors.ToArray()
    }
}
