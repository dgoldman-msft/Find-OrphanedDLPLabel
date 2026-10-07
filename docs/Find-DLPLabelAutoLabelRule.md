---
external help file: Find-OrphanedDLPLabel-help.xml
Module Name: Find-OrphanedDLPLabel
online version: https://github.com/dgoldman-msft/Find-OrphanedDLPLabel/blob/main/docs/Find-DLPLabelAutoLabelRule.md
schema: 2.0.0
---

# Find-DLPLabelAutoLabelRule

## SYNOPSIS
Finds auto-labeling rules that reference a sensitivity-label GUID.

## SYNTAX

```
Find-DLPLabelAutoLabelRule [-LabelGuid] <Guid> [-LogPath] <String> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Searches auto-labeling rule actions for the supplied GUID, retrieves each
matching rule's parent policy, and identifies simulation or test modes.

## EXAMPLES

### Example 1

```powershell
Find-DLPLabelAutoLabelRule -LabelGuid 'f42aa342-8706-4288-bd11-ebb85995028c' -LogPath '.\auto-label.log'
```

Finds auto-labeling rules and parent policies that reference the specified label GUID.

## PARAMETERS

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
The path used to record findings and errors.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
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

Returns an object containing Rules and Error.

## NOTES

This is an internal helper function and is not exported by the module.

## RELATED LINKS
