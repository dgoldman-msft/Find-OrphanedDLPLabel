function Get-TimeStamp {
    <#
        .SYNOPSIS
            Returns a timestamp formatted for log entries.

        .DESCRIPTION
            Returns the current local date and time in MM/dd/yy HH:mm:ss format with
            surrounding brackets and a trailing hyphen.

        .OUTPUTS
            System.String
    #>

    [CmdletBinding()]
    param()

    return '[{0:MM/dd/yy} {0:HH:mm:ss}] -' -f (Get-Date)
}
