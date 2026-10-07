---
external help file: Find-OrphanedDLPLabel-help.xml
Module Name: Find-OrphanedDLPLabel
online version: https://github.com/dgoldman-msft/Find-OrphanedDLPLabel/blob/main/docs/Get-TimeStamp.md
schema: 2.0.0
---

# Get-TimeStamp

## SYNOPSIS
Returns a timestamp formatted for log entries.

## SYNTAX

```
Get-TimeStamp [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Returns the current local date and time in MM/dd/yy HH:mm:ss format with
surrounding brackets and a trailing hyphen.

## EXAMPLES

### Example 1

```powershell
Get-TimeStamp
```

Returns a timestamp such as `[10/07/26 17:00:00] -` for use in a log entry.

## PARAMETERS

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

### System.String

Returns the formatted local timestamp.

## NOTES

This is an internal helper function and is not exported by the module.

## RELATED LINKS
