---
external help file: Find-OrphanedDLPLabel-help.xml
Module Name: Find-OrphanedDLPLabel
online version: https://github.com/dgoldman-msft/Find-OrphanedDLPLabel/blob/main/docs/Find-DLPLabelAuditRecord.md
schema: 2.0.0
---

# Find-DLPLabelAuditRecord

## SYNOPSIS
Searches the Unified Audit Log for a sensitivity-label GUID.

## SYNTAX

```
Find-DLPLabelAuditRecord [-LabelGuid] <Guid> [-AuditDaysBack] <Int32> [-AuditChunkDays] <Int32>
 [-ShowFullAuditDetails] [-LogPath] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Searches the requested audit history in date chunks and returns matching
records whose AuditData contains the supplied GUID.
Individual chunk
failures are collected without discarding results from successful chunks.

## EXAMPLES

### Example 1

```powershell
Find-DLPLabelAuditRecord -LabelGuid 'f42aa342-8706-4288-bd11-ebb85995028c' -AuditDaysBack 90 -AuditChunkDays 14 -LogPath '.\audit.log'
```

Searches 90 days of audit data in 14-day chunks and returns matching records and chunk errors.

### Example 2

```powershell
Find-DLPLabelAuditRecord -LabelGuid 'f42aa342-8706-4288-bd11-ebb85995028c' -AuditDaysBack 90 -AuditChunkDays 14 -ShowFullAuditDetails -LogPath '.\audit.log'
```

Displays complete matching audit payloads in the console in addition to writing them to the log.

## PARAMETERS

### -AuditChunkDays
The number of days included in each audit query.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -AuditDaysBack
The number of historical days to search. Valid values are 1 through 365.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -ShowFullAuditDetails
Displays complete matching audit payloads in the console. Complete payloads are always written to the log regardless of this switch.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -LabelGuid
The sensitivity-label GUID to locate.

```yaml
Type: Guid
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogPath
The path used to record progress, findings, and errors.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
Specifies how the command responds to progress updates.

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

You cannot pipe input to this function.

## OUTPUTS

### System.Management.Automation.PSCustomObject

Returns an object containing `Records` and `Errors` arrays. By default, each record contains `CreationTime`, `Operation`, `UserId`, `Workload`, `Subject`, `ObjectId`, `FileName`, `LabelGuid`, and `LabelEvidence`.

Each complete matching payload is written to the log as one JSON line. `ShowFullAuditDetails` also displays those `[FOUND]` payloads in the console. Returned records remain limited to label evidence and item context.

## NOTES

This is an internal helper function and is not exported by the module.

## RELATED LINKS
