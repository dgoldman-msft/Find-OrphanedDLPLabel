function Find-OrphanedDLPLabel {
    <#
        .SYNOPSIS
            Investigates a potentially orphaned Microsoft Purview sensitivity-label GUID.

        .DESCRIPTION
            Checks the current label catalog, auto-labeling rules, DLP compliance rules,
            Unified Audit Log, and optionally a Microsoft Purview Compliance Search.
            Every stage writes to a timestamped text log, and the command returns one
            structured result object.

            .PARAMETER LabelGuid
            The sensitivity-label GUID to investigate.

            .PARAMETER ExchangeLocation
            An Exchange mailbox or distribution location for the optional Compliance Search.

            .PARAMETER Subjects
                One or more exact message subjects included when SearchMessages is used.

            .PARAMETER SearchMessages
                Runs the optional Exchange message search. Subjects must be supplied unless
                IncludeMessageLabelInfo is also used.

            .PARAMETER IncludeMessageLabelInfo
                Runs the optional Exchange message search with a SensitivityLabel query for
                the supplied LabelGuid. When combined with SearchMessages and Subjects, both
                filters must match.

            .PARAMETER AuditDaysBack
                The number of days of Unified Audit Log history to search. The default is
                90 days, and the maximum is 365 days.

            .PARAMETER AuditChunkDays
            The number of days in each Unified Audit Log query. The default is 30.

            .PARAMETER ShowFullAuditDetails
                Displays complete matching audit payloads in the console. Complete payloads
                are always written to the log regardless of this switch.

            .PARAMETER SearchTimeoutSeconds
            The maximum time to wait for the optional Compliance Search. The default is 120.

            .PARAMETER UserPrincipalName
            The account passed to Connect-ExchangeOnline and Connect-IPPSSession
            when a new connection is required.

            .PARAMETER LogPath
            The text log path. The default is a timestamped file in the current directory.

        .EXAMPLE
            Find-OrphanedDLPLabel -LabelGuid 'f42aa342-8706-4288-bd11-ebb85995028c'

            Investigates the GUID across the catalog, policies, rules, and audit log.

        .EXAMPLE
            Find-OrphanedDLPLabel -LabelGuid 'f42aa342-8706-4288-bd11-ebb85995028c' -SearchMessages -ExchangeLocation 'user@contoso.com' -Subjects 'Quarterly Review'

            Runs the standard investigation and a subject-based message search.

        .EXAMPLE
            Find-OrphanedDLPLabel -LabelGuid 'f42aa342-8706-4288-bd11-ebb85995028c' -IncludeMessageLabelInfo -ExchangeLocation 'user@contoso.com'

            Searches the Exchange location for messages with the specified label GUID
            and includes the label name and GUID in the search summary.

        .OUTPUTS
            Find.OrphanedDLPLabel.Result
    #>

    [CmdletBinding(DefaultParameterSetName = 'Discovery')]
    [OutputType('Find.OrphanedDLPLabel.Result')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [guid]$LabelGuid,

        [Parameter(Mandatory, ParameterSetName = 'ComplianceSearch')]
        [ValidateNotNullOrEmpty()]
        [string]$ExchangeLocation,

        [Parameter(ParameterSetName = 'ComplianceSearch')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Subjects,

        [Parameter(ParameterSetName = 'ComplianceSearch')]
        [switch]$SearchMessages,

        [Parameter(ParameterSetName = 'ComplianceSearch')]
        [switch]$IncludeMessageLabelInfo,

        [ValidateRange(1, 365)]
        [int]$AuditDaysBack = 90,

        [ValidateRange(1, 365)]
        [int]$AuditChunkDays = 30,

        [switch]$ShowFullAuditDetails,

        [Parameter(ParameterSetName = 'ComplianceSearch')]
        [ValidateRange(10, 3600)]
        [int]$SearchTimeoutSeconds = 120,

        [string]$UserPrincipalName,

        [ValidateNotNullOrEmpty()]
        [string]$LogPath = (Join-Path (Get-Location) "find-orphaned-dlp-label-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt")
    )

    $resolvedLogPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($LogPath)
    $errors = [System.Collections.Generic.List[string]]::new()

    try {
        if ($PSCmdlet.ParameterSetName -eq 'ComplianceSearch') {
            if (-not ($SearchMessages -or $IncludeMessageLabelInfo)) {
                throw 'Specify SearchMessages, IncludeMessageLabelInfo, or both to run the optional message search.'
            }
            if ($SearchMessages -and $Subjects.Count -eq 0 -and -not $IncludeMessageLabelInfo) {
                throw 'SearchMessages requires at least one subject unless IncludeMessageLabelInfo is also specified.'
            }
        }

        Write-ToLogFile -StringObject ("  [INFO]    " + ("Starting investigation for sensitivity-label GUID $LabelGuid.")) -LogFile $resolvedLogPath -ForegroundColor Gray
        Connect-DLPLabelComplianceSession -UserPrincipalName $UserPrincipalName -LogPath $resolvedLogPath

        $catalogResult = Get-DLPLabelCatalogEntry -LabelGuid $LabelGuid -LogPath $resolvedLogPath
        if ($catalogResult.Error) {
            $errors.Add($catalogResult.Error)
        }

        $autoLabelResult = Find-DLPLabelAutoLabelRule -LabelGuid $LabelGuid -LogPath $resolvedLogPath
        if ($autoLabelResult.Error) {
            $errors.Add($autoLabelResult.Error)
        }

        $dlpResult = Find-DLPLabelDlpRule -LabelGuid $LabelGuid -LogPath $resolvedLogPath
        if ($dlpResult.Error) {
            $errors.Add($dlpResult.Error)
        }

        $auditResult = Find-DLPLabelAuditRecord -LabelGuid $LabelGuid -AuditDaysBack $AuditDaysBack -AuditChunkDays $AuditChunkDays -ShowFullAuditDetails:$ShowFullAuditDetails -LogPath $resolvedLogPath
        foreach ($auditError in $auditResult.Errors) {
            $errors.Add($auditError)
        }

        $complianceResult = $null
        if ($PSCmdlet.ParameterSetName -eq 'ComplianceSearch') {
            $complianceResult = Find-DLPLabelComplianceItem -ExchangeLocation $ExchangeLocation -Subjects $Subjects -LabelGuid $LabelGuid -LabelName $catalogResult.Label.DisplayName -IncludeMessageLabelInfo:$IncludeMessageLabelInfo -SearchTimeoutSeconds $SearchTimeoutSeconds -LogPath $resolvedLogPath
            if ($complianceResult.Error) {
                $errors.Add($complianceResult.Error)
            }
        }
        else {
            Write-ToLogFile -StringObject ("`n==================== " + ('5. Optional Compliance Search') + " ====================") -LogFile $resolvedLogPath -ForegroundColor Cyan
            Write-ToLogFile -StringObject ("  [INFO]    " + ('Skipped. Use SearchMessages or IncludeMessageLabelInfo with ExchangeLocation to run a message search.')) -LogFile $resolvedLogPath -ForegroundColor Yellow
        }

        $complianceSearchFinding = if ($null -eq $complianceResult) {
            'Skipped'
        }
        else {
            $null -ne $complianceResult.Search
        }

        $findings = [ordered]@{
            LabelInCatalog     = $null -ne $catalogResult.Label
            AutoLabelRuleMatch = $autoLabelResult.Rules.Count -gt 0
            DlpRuleMatch       = $dlpResult.Rules.Count -gt 0
            AuditLogMatch      = $auditResult.Records.Count -gt 0
            ComplianceSearch   = $complianceSearchFinding
        }

        Write-ToLogFile -StringObject ("`n==================== " + ('SUMMARY') + " ====================") -LogFile $resolvedLogPath -ForegroundColor Cyan
        foreach ($finding in $findings.GetEnumerator()) {
            if ($finding.Value -is [string] -and $finding.Value -eq 'Skipped') {
                Write-ToLogFile -StringObject ("  [INFO]    " + ("$($finding.Key): skipped.")) -LogFile $resolvedLogPath -ForegroundColor Gray
                continue
            }
            $state = if ($finding.Value) { 'FOUND evidence' } else { 'no evidence' }
            if ($finding.Value) {
                Write-ToLogFile -StringObject ("  [FOUND]   " + ("$($finding.Key): $state.")) -LogFile $resolvedLogPath -ForegroundColor Green
            }
            else {
                Write-ToLogFile -StringObject ("  [INFO]    " + ("$($finding.Key): $state.")) -LogFile $resolvedLogPath -ForegroundColor Gray
            }
        }

        $isOrphaned = if ($catalogResult.Succeeded) {
            $null -eq $catalogResult.Label
        }
        else {
            $null
        }

        if ($isOrphaned -eq $true -and -not (
                $findings.AutoLabelRuleMatch -or
                $findings.DlpRuleMatch -or
                $findings.AuditLogMatch
            )) {
            Write-ToLogFile -StringObject ("  [PARTIAL] " + ('No current label, rule, policy, or audit evidence was found. The GUID may be orphaned seed data or a simulation-only artifact.')) -LogFile $resolvedLogPath -ForegroundColor Yellow
        }
        elseif ($null -eq $isOrphaned) {
            Write-ToLogFile -StringObject ("  [PARTIAL] " + ('The label catalog query failed, so orphaned status could not be determined.')) -LogFile $resolvedLogPath -ForegroundColor Yellow
        }
        else {
            Write-ToLogFile -StringObject ("  [FOUND]   " + ('The investigation found evidence. Review the returned object and FOUND log entries.')) -LogFile $resolvedLogPath -ForegroundColor Green
        }

        Write-ToLogFile -StringObject ("  [INFO]    " + ("Full log saved to: $resolvedLogPath")) -LogFile $resolvedLogPath -ForegroundColor Gray

        $auditRecordItems = @($auditResult.Records)
        $auditRecordText = if (-not $ShowFullAuditDetails) {
            '[INFO]    Use -ShowFullAuditDetails to display complete matching audit records in the console.'
        }
        elseif ($auditRecordItems.Count -gt 0) {
            ($auditRecordItems | ForEach-Object { $_.ToString().Trim() }) -join ([Environment]::NewLine + [Environment]::NewLine)
        }
        else {
            '{}'
        }
        $auditRecords = [pscustomobject]@{
            Count = $auditRecordItems.Count
        }
        $auditRecords | Add-Member -MemberType ScriptMethod -Name ToString -Value {
            return $auditRecordText
        }.GetNewClosure() -Force
        $auditRecords | Add-Member -MemberType ScriptMethod -Name GetItems -Value {
            return , $auditRecordItems
        }.GetNewClosure() -Force

        $labelName = if ($catalogResult.Label -and $catalogResult.Label.DisplayName) {
            [string]$catalogResult.Label.DisplayName
        }
        elseif ($catalogResult.Label) {
            ([string]$catalogResult.Label -split '/Configuration/')[-1]
        }
        else {
            $null
        }

        $result = [pscustomobject]@{
            PSTypeName       = 'Find.OrphanedDLPLabel.Result'
            LabelGuid        = $LabelGuid
            IsOrphaned       = $isOrphaned
            Findings         = [pscustomobject]$findings
            Label            = $labelName
            AutoLabelRules   = $autoLabelResult.Rules
            DlpRules         = $dlpResult.Rules
            AuditRecords     = $auditRecords
            ComplianceSearch = if ($complianceResult) { $complianceResult.Search } else { $null }
            Errors           = $errors.ToArray()
            LogPath          = $resolvedLogPath
        }
        return $result
    }
    catch {
        $message = "Investigation stopped: $($_.Exception.Message)"
        try {
            Write-ToLogFile -StringObject ("  [NOTHING] " + ($message)) -LogFile $resolvedLogPath -ForegroundColor Red
        }
        catch {
            Write-Error "$message The log could not be updated: $($_.Exception.Message)"
        }
        throw
    }
}
