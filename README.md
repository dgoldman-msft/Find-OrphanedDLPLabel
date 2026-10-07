# Find-OrphanedDLPLabel

`Find-OrphanedDLPLabel` is a PowerShell module that investigates a Microsoft Purview sensitivity-label GUID that appears in Content Explorer, DLP, or auto-labeling results but no longer resolves through `Get-Label`.

## What the module does

1. **Accepts a sensitivity-label GUID.** The module investigates a Microsoft Purview sensitivity label that may no longer exist but is still referenced by policies, rules, audit records, or content.
2. **Prepares PowerShell dependencies.** It checks whether `ExchangeOnlineManagement` is installed. If the module is missing, it installs it for the current user and imports it.
3. **Connects to Microsoft 365 services.** It establishes Exchange Online and Security & Compliance PowerShell connections and reuses existing active connections.
4. **Checks the current label catalog.** It runs `Get-Label` to determine whether the GUID still belongs to an active or disabled sensitivity label.
5. **Searches auto-labeling rules.** It examines enabled and disabled auto-labeling rules for references to the GUID and checks matching parent policies for simulation or test mode.
6. **Searches DLP compliance rules.** It checks DLP rules for references to the GUID in sensitive-information conditions or sensitivity-label actions.
7. **Searches the Unified Audit Log.** It searches 90 days by default, supports a configurable range from 1 through 365 days, and returns records whose audit data contains the label GUID.
8. **Optionally searches affected Exchange content.** `SearchMessages` runs a subject-based search. `IncludeMessageLabelInfo` searches by sensitivity-label GUID and includes the label name and GUID in the result. Both switches can be combined.
9. **Determines whether the label may be orphaned.** A label is potentially orphaned when the catalog query succeeds but the GUID is no longer present. Evidence from rules and audit records is reported separately.
10. **Creates a timestamped log.** Every stage records connection activity, progress, findings, warnings, and failures in the same UTF-8 text log.
11. **Returns structured results.** The result contains label information, orphaned status, auto-labeling and DLP rule matches, audit records, Compliance Search results, errors, and the log path.
12. **Avoids changing labels or content.** The investigation is read-only except for creating and starting the optional Compliance Search definition.

## Requirements

- PowerShell 7.1 or later.
- Access to PowerShell Gallery when the [ExchangeOnlineManagement](https://www.powershellgallery.com/packages/ExchangeOnlineManagement) module is not already installed.
- An account with permissions to connect to Security & Compliance PowerShell and read the Purview data being queried.
- Unified Audit permissions to search audit records.
- For optional Compliance Search, reconnect with a search-only session when required:

  ```powershell
  Connect-IPPSSession -EnableSearchOnlySession
  ```

The command installs `ExchangeOnlineManagement` for the current user when it is missing, imports it, and reuses active Exchange Online and Security & Compliance PowerShell connections. It does not grant permissions.

## Module structure

```text
.
|-- 1.0
|   |-- Find-OrphanedDLPLabel.Format.ps1xml
|   |-- Find-OrphanedDLPLabel.psd1
|   |-- Find-OrphanedDLPLabel.psm1
|   |-- functions
|   |   `-- Find-OrphanedDLPLabel.ps1
|   `-- internal
|       `-- functions
|           |-- Connect-DLPLabelComplianceSession.ps1
|           |-- Find-DLPLabelAuditRecord.ps1
|           |-- Find-DLPLabelAutoLabelRule.ps1
|           |-- Find-DLPLabelComplianceItem.ps1
|           |-- Find-DLPLabelDlpRule.ps1
|           |-- Get-DLPLabelCatalogEntry.ps1
|           |-- Get-TimeStamp.ps1
|           `-- Write-ToLogFile.ps1
|-- docs
|   |-- Find-OrphanedDLPLabel.md
|   `-- README.md
|-- LICENSE
`-- README.md
```

## Import

```powershell
Import-Module .\1.0\Find-OrphanedDLPLabel.psd1
```

## Examples

Investigate a label and search the default 90 days of audit data:

```powershell
$result = Find-OrphanedDLPLabel `
    -LabelGuid 'f42aa342-8706-4288-bd11-ebb85995028c'
```

Use smaller audit chunks and save the log in a specific folder:

```powershell
$result = Find-OrphanedDLPLabel `
    -LabelGuid 'f42aa342-8706-4288-bd11-ebb85995028c' `
    -AuditDaysBack 180 `
    -AuditChunkDays 14 `
    -LogPath '.\logs\orphaned-label.txt'
```

Show each complete matching audit payload in the console:

```powershell
$result = Find-OrphanedDLPLabel `
    -LabelGuid 'f42aa342-8706-4288-bd11-ebb85995028c' `
    -ShowFullAuditDetails
```

Also run a Compliance Search against a mailbox:

```powershell
$result = Find-OrphanedDLPLabel `
    -LabelGuid 'f42aa342-8706-4288-bd11-ebb85995028c' `
    -SearchMessages `
    -ExchangeLocation 'user@contoso.com' `
    -Subjects 'Sales & Marketing Alignment', 'Marketing Campaign Touchpoint'
```

Search a mailbox for messages carrying the sensitivity label:

```powershell
$result = Find-OrphanedDLPLabel `
    -LabelGuid 'f42aa342-8706-4288-bd11-ebb85995028c' `
    -IncludeMessageLabelInfo `
    -ExchangeLocation 'user@contoso.com'
```

Use both switches to require a matching subject and sensitivity label:

```powershell
$result = Find-OrphanedDLPLabel `
    -LabelGuid 'f42aa342-8706-4288-bd11-ebb85995028c' `
    -SearchMessages `
    -IncludeMessageLabelInfo `
    -ExchangeLocation 'user@contoso.com' `
    -Subjects 'Sales & Marketing Alignment'
```

Inspect the structured outcome:

```powershell
$result.Findings
$result.AuditRecords
$result.AuditRecords.Count
$result.AuditRecords.GetItems()
$result.Errors
```

## Output

The command returns one `Find.OrphanedDLPLabel.Result` object containing:

- `LabelGuid`
- `IsOrphaned`
- `Findings`
- `Label`
- `AutoLabelRules`
- `DlpRules`
- `AuditRecords`
- `ComplianceSearch`
- `Errors`
- `LogPath`

`IsOrphaned` is `$true` only when the label catalog was queried successfully and the GUID was not found. A failed catalog query produces `$null` instead of claiming that the label is orphaned.

`Label` contains only the matching label's display name. By default, `AuditRecords` contains only label-related evidence and item context: creation time, operation, user, workload, message subject or content target, label GUID, and the exact audit properties that matched the GUID. The default result view displays each audit record on its own line.

Stage 4 displays each `Searching audit chunk ...` line in the console. Complete matching audit payloads are always written to the log as one JSON line per record. Use `ShowFullAuditDetails` to also display those `[FOUND]` payloads in the console.

Without `ShowFullAuditDetails`, the final console result replaces the `AuditRecords` display with the same guidance shown in stage 4, keeping the console summary concise. All matching data is still written to the log and retained in the result. With the switch, the final console result displays every audit record.

`AuditRecords` is a non-enumerable display view so PowerShell does not insert collection commas or truncate the output according to `$FormatEnumerationLimit`. Use `$result.AuditRecords.Count` for the record count and `$result.AuditRecords.GetItems()` to retrieve the structured record objects regardless of the display mode.

When the optional Compliance Search is not requested, `Findings.ComplianceSearch` is `Skipped` rather than reporting that no evidence was found.

## Logging

The default log is created in the current directory:

```text
find-orphaned-dlp-label-yyyyMMdd-HHmmss.txt
```

All internal discovery functions accept the active log path and record their start, findings, warnings, and failures through the shared logger. The command also writes progress and a final summary to the console.

## Help

PlatyPS-compatible help for the public command and every internal function is available in the [command reference](docs/README.md).

```powershell
Get-Help Find-OrphanedDLPLabel -Full
```

## Safety

`Find-OrphanedDLPLabel` is read-only except for creating the optional Compliance Search definition and starting that search. It does not change labels, rules, policies, or content.

## License

This project is licensed under the [MIT License](LICENSE).
