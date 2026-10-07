---
external help file: Find-OrphanedDLPLabel-help.xml
Module Name: Find-OrphanedDLPLabel
online version: https://github.com/dgoldman-msft/Find-OrphanedDLPLabel/blob/main/docs/Find-OrphanedDLPLabel.md
schema: 2.0.0
---

# Find-OrphanedDLPLabel

## SYNOPSIS

Investigates a potentially orphaned Microsoft Purview sensitivity-label GUID.

## SYNTAX

### Discovery (Default)

```text
Find-OrphanedDLPLabel [-LabelGuid] <Guid> [-AuditDaysBack <Int32>] [-AuditChunkDays <Int32>]
 [-ShowFullAuditDetails] [-UserPrincipalName <String>] [-LogPath <String>] [<CommonParameters>]
```

### ComplianceSearch

```text
Find-OrphanedDLPLabel [-LabelGuid] <Guid> -ExchangeLocation <String> [-Subjects <String[]>]
 [-SearchMessages] [-IncludeMessageLabelInfo] [-AuditDaysBack <Int32>] [-AuditChunkDays <Int32>]
 [-ShowFullAuditDetails] [-SearchTimeoutSeconds <Int32>] [-UserPrincipalName <String>] [-LogPath <String>]
 [<CommonParameters>]
```

## DESCRIPTION

`Find-OrphanedDLPLabel` checks whether a sensitivity-label GUID exists in the current label catalog and searches for references in auto-labeling rules, parent auto-labeling policies, DLP compliance rules, and the Unified Audit Log.

`SearchMessages` creates a subject-based Microsoft Purview Compliance Search. `IncludeMessageLabelInfo` searches Exchange messages with `SensitivityLabel:<LabelGuid>` and includes the label name and GUID in the returned search summary. Both switches can be combined to require the subject and label filters.

Every internal discovery stage writes timestamped entries to a text log. The command returns one structured result object containing the evidence, errors, orphaned status, and log path.

## EXAMPLES

### Example 1: Run a standard investigation

```powershell
Find-OrphanedDLPLabel -LabelGuid 'f42aa342-8706-4288-bd11-ebb85995028c'
```

Checks the label catalog, auto-labeling rules, DLP rules, and the last 90 days of audit records.

### Example 2: Change the audit window

```powershell
Find-OrphanedDLPLabel -LabelGuid 'f42aa342-8706-4288-bd11-ebb85995028c' -AuditDaysBack 90 -AuditChunkDays 14
```

Searches the last 90 days of audit data in 14-day chunks.

### Example 3: Run an optional Compliance Search

```powershell
Find-OrphanedDLPLabel -LabelGuid 'f42aa342-8706-4288-bd11-ebb85995028c' -SearchMessages -ExchangeLocation 'user@contoso.com' -Subjects 'Quarterly Review', 'Legal Hold Notice'
```

Runs the standard investigation and searches the specified Exchange location for either subject.

### Example 4: Search messages by sensitivity label

```powershell
Find-OrphanedDLPLabel -LabelGuid 'f42aa342-8706-4288-bd11-ebb85995028c' -IncludeMessageLabelInfo -ExchangeLocation 'user@contoso.com'
```

Searches the Exchange location for the sensitivity-label GUID and returns the label name and GUID in the Compliance Search summary.

### Example 5: Show complete audit payloads in the console

```powershell
Find-OrphanedDLPLabel -LabelGuid 'f42aa342-8706-4288-bd11-ebb85995028c' -ShowFullAuditDetails
```

Displays each complete matching audit payload as a `[FOUND]` console entry. Complete payloads are written to the log even when this switch is omitted.

### Example 6: Select structured evidence

```powershell
$result = Find-OrphanedDLPLabel -LabelGuid 'f42aa342-8706-4288-bd11-ebb85995028c'
$result.Findings
$result.AuditRecords
$result.AuditRecords.Count
$result.AuditRecords.GetItems()
$result.Errors
```

Stores and examines the investigation result. `AuditRecords` provides a complete display without collection commas or truncation, while `GetItems()` returns the structured record objects.

## PARAMETERS

### -AuditChunkDays

Specifies the number of days in each Unified Audit Log query. Smaller chunks can reduce failures caused by long search durations.

```yaml
Type: System.Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 30
Accept pipeline input: False
Accept wildcard characters: False
```

### -AuditDaysBack

Specifies the number of days of Unified Audit Log history to search. Valid values are 1 through 365.

```yaml
Type: System.Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 90
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExchangeLocation

Specifies the Exchange mailbox or distribution location for the optional message search.

```yaml
Type: System.String
Parameter Sets: ComplianceSearch
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ShowFullAuditDetails

Displays complete matching audit payloads in the console. Complete payloads are always written to the log regardless of this switch.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -LabelGuid

Specifies the sensitivity-label GUID to investigate.

```yaml
Type: System.Guid
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeMessageLabelInfo

Searches Exchange messages using `SensitivityLabel:<LabelGuid>` and includes the label display name and GUID in the returned Compliance Search summary.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: ComplianceSearch
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogPath

Specifies the text log path. The default is a timestamped file named `find-orphaned-dlp-label-yyyyMMdd-HHmmss.txt` in the current directory. Missing parent directories are created.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Timestamped file in the current directory
Accept pipeline input: False
Accept wildcard characters: False
```

### -SearchTimeoutSeconds

Specifies how long to wait for the optional Compliance Search to finish.

```yaml
Type: System.Int32
Parameter Sets: ComplianceSearch
Aliases:

Required: False
Position: Named
Default value: 120
Accept pipeline input: False
Accept wildcard characters: False
```

### -SearchMessages

Runs the optional subject-based message search. Supply `Subjects` unless `IncludeMessageLabelInfo` is also specified.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: ComplianceSearch
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Subjects

Specifies one or more exact message subjects for `SearchMessages`. Subjects are combined with `OR`. When `IncludeMessageLabelInfo` is also used, the subject expression and sensitivity-label expression are combined with `AND`.

```yaml
Type: System.String[]
Parameter Sets: ComplianceSearch
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UserPrincipalName

Specifies the account passed to `Connect-ExchangeOnline` and `Connect-IPPSSession` when the command must create Exchange Online or Security & Compliance PowerShell connections.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: `-Debug`, `-ErrorAction`, `-ErrorVariable`, `-InformationAction`, `-InformationVariable`, `-OutVariable`, `-OutBuffer`, `-PipelineVariable`, `-ProgressAction`, `-Verbose`, and `-WarningAction`. For more information, see [about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

You cannot pipe input to this command.

## OUTPUTS

### Find.OrphanedDLPLabel.Result

The command returns an object containing `LabelGuid`, `IsOrphaned`, `Findings`, `Label`, `AutoLabelRules`, `DlpRules`, `AuditRecords`, `ComplianceSearch`, `Errors`, and `LogPath`.

`IsOrphaned` is `$null` when the label catalog query fails.

`Label` contains only the matching label's display name. By default, `AuditRecords` contains creation time, operation, user, workload, message subject or content target, label GUID, and the exact properties that matched the GUID. Each record appears on its own line.

Stage 4 displays every audit-chunk search in the console. Matching audit payloads are always written to the log as one JSON line per record. With `ShowFullAuditDetails`, the same `[FOUND]` payloads are also displayed in the console. When the optional Compliance Search is not requested, `Findings.ComplianceSearch` is `Skipped`.

Without `ShowFullAuditDetails`, the final console result displays the stage-4 guidance in place of the audit-record collection. All matching data remains in the log and returned result. With the switch, every audit record is displayed.

`AuditRecords` uses a non-enumerable display view to prevent collection commas and `$FormatEnumerationLimit` truncation. Use `AuditRecords.Count` for the count and `AuditRecords.GetItems()` to retrieve the structured records regardless of the display mode.

## NOTES

The command requires Exchange Online and Security & Compliance PowerShell commands supplied through the ExchangeOnlineManagement module. When the module is missing, the command installs it from PowerShell Gallery for the current user and imports it. Existing active connections are reused.

The command is read-only except for creating and starting the optional Compliance Search. It does not remove the search definition after completion.

If Compliance Search fails with `AADSTS500011`, disconnect and reconnect using `Connect-IPPSSession -EnableSearchOnlySession`.

## RELATED LINKS

[Connect to Security & Compliance PowerShell](https://learn.microsoft.com/powershell/exchange/connect-to-scc-powershell)

[Search the audit log](https://learn.microsoft.com/purview/audit-search)
