---
external help file: Find-OrphanedDLPLabel-help.xml
Module Name: Find-OrphanedDLPLabel
online version: https://github.com/dgoldman-msft/Find-OrphanedDLPLabel/blob/main/docs/Write-ToLogFile.md
schema: 2.0.0
---

# Write-ToLogFile

## SYNOPSIS
Writes a timestamped message to a UTF-8 log file.

## SYNTAX

```
Write-ToLogFile [-StringObject] <String> -LogFile <String> [-ForegroundColor <ConsoleColor>] [-LogOnly]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Creates the log directory when necessary, writes blank lines represented by
an empty string or leading newline characters, and prefixes non-empty log
entries with Get-TimeStamp.
Messages can also be displayed in the console.

## EXAMPLES

### Example 1

```powershell
Write-ToLogFile -StringObject 'Investigation started.' -LogFile '.\investigation.log' -ForegroundColor Cyan
```

Displays the message in cyan and appends a timestamped copy to the log file.

## PARAMETERS

### -ForegroundColor
The optional console color used when displaying the message.

```yaml
Type: ConsoleColor
Parameter Sets: (All)
Aliases:
Accepted values: Black, DarkBlue, DarkGreen, DarkCyan, DarkRed, DarkMagenta, DarkYellow, Gray, DarkGray, Blue, Green, Cyan, Red, Magenta, Yellow, White

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogFile
The destination log file path.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogOnly
Suppresses console output while continuing to write to the log file.

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

### -StringObject
The message to write.
An empty string writes a blank line.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

You cannot pipe input to this function.

## OUTPUTS

### None

This function does not return output.

## NOTES

This is an internal helper function and is not exported by the module.

## RELATED LINKS
