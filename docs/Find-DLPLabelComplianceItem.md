---
external help file: Find-OrphanedDLPLabel-help.xml
Module Name: Find-OrphanedDLPLabel
online version: https://github.com/dgoldman-msft/Find-OrphanedDLPLabel/blob/main/docs/Find-DLPLabelComplianceItem.md
schema: 2.0.0
---

# Find-DLPLabelComplianceItem

## SYNOPSIS
Runs a Compliance Search for messages by subject, sensitivity label, or both.

## SYNTAX

```
Find-DLPLabelComplianceItem [-ExchangeLocation] <String> [[-Subjects] <String[]>] [-LabelGuid] <Guid>
 [[-LabelName] <String>] [-IncludeMessageLabelInfo] [-SearchTimeoutSeconds] <Int32>
 [-LogPath] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Creates and starts a Compliance Search against an Exchange location. The query
can contain subjects, a `SensitivityLabel` GUID filter, or both. The function
polls until the search completes, fails, partially succeeds, or times out.

## EXAMPLES

### Example 1

```powershell
Find-DLPLabelComplianceItem -ExchangeLocation 'user@contoso.com' -LabelGuid 'f42aa342-8706-4288-bd11-ebb85995028c' -LabelName 'Confidential' -IncludeMessageLabelInfo -SearchTimeoutSeconds 120 -LogPath '.\compliance-search.log'
```

Searches messages for the sensitivity-label GUID and includes its display name and GUID in the returned summary.

## PARAMETERS

### -ExchangeLocation
The mailbox or Exchange location to search.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogPath
The path used to record search status, findings, and errors.

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

### -IncludeMessageLabelInfo
Adds `SensitivityLabel:<LabelGuid>` to the query and includes label details in the returned search summary.

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
The sensitivity-label GUID used when `IncludeMessageLabelInfo` is specified.

```yaml
Type: Guid
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LabelName
The sensitivity-label display name included in the returned search summary.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
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

### -SearchTimeoutSeconds
The maximum number of seconds to wait for the search.

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

### -Subjects
Optional exact message subjects combined with the `OR` operator.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
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

Returns an object containing `Search` and `Error`. `Search` is a concise summary containing `Name`, `Status`, `Items`, `Size`, `ExchangeLocation`, `Query`, `Label`, and `LabelGuid`.

## NOTES

This is an internal helper function and is not exported by the module.

## RELATED LINKS
