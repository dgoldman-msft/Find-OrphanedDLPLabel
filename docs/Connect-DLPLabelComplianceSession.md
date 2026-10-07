---
external help file: Find-OrphanedDLPLabel-help.xml
Module Name: Find-OrphanedDLPLabel
online version: https://github.com/dgoldman-msft/Find-OrphanedDLPLabel/blob/main/docs/Connect-DLPLabelComplianceSession.md
schema: 2.0.0
---

# Connect-DLPLabelComplianceSession

## SYNOPSIS
Connects to Exchange Online and Security & Compliance PowerShell.

## SYNTAX

```
Connect-DLPLabelComplianceSession [[-UserPrincipalName] <String>] [-LogPath] <String>
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Installs ExchangeOnlineManagement for the current user when it is missing,
imports the module, and reuses active Exchange Online and IPPS connections.
Only missing connections are opened, and both are verified before returning.

## EXAMPLES

### Example 1

```powershell
Connect-DLPLabelComplianceSession -UserPrincipalName 'admin@contoso.com' -LogPath '.\connection.log'
```

Ensures the module is available and establishes or reuses both required service connections.

## PARAMETERS

### -LogPath
The path used to record module and connection activity.

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

### -UserPrincipalName
The optional account used by Connect-ExchangeOnline and Connect-IPPSSession.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
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

Throws when module installation or import fails, a connection cannot be established or verified, or `Get-Label` is unavailable after connecting.

## RELATED LINKS
