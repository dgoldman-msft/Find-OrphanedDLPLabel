function Write-ToLogFile {
    <#
        .SYNOPSIS
            Writes a timestamped message to a UTF-8 log file.

        .DESCRIPTION
            Creates the log directory when necessary, writes blank lines represented by
            an empty string or leading newline characters, and prefixes non-empty log
            entries with Get-TimeStamp. Messages can also be displayed in the console.

            .PARAMETER StringObject
            The message to write. An empty string writes a blank line.

            .PARAMETER LogFile
            The destination log file path.

            .PARAMETER ForegroundColor
            The optional console color used when displaying the message.

            .PARAMETER LogOnly
            Suppresses console output while continuing to write to the log file.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [AllowEmptyString()]
        [string]$StringObject,

        [Parameter(Mandatory)]
        [string]$LogFile,

        [System.ConsoleColor]$ForegroundColor,

        [switch]$LogOnly
    )

    $targetDirectory = Split-Path -Path $LogFile -Parent
    if ($targetDirectory -and -not (Test-Path -LiteralPath $targetDirectory)) {
        New-Item -Path $targetDirectory -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }

    if (-not $LogOnly -and $StringObject -ne '') {
        if ($PSBoundParameters.ContainsKey('ForegroundColor')) {
            Write-Host $StringObject -ForegroundColor $ForegroundColor
        }
        else {
            Write-Host $StringObject
        }
    }

    if ($StringObject -eq '') {
        Add-Content -LiteralPath $LogFile -Value '' -Encoding utf8
        return
    }

    $content = $StringObject
    while ($content.StartsWith("`n")) {
        Add-Content -LiteralPath $LogFile -Value '' -Encoding utf8
        $content = $content.Substring(1)
    }

    if ($content) {
        Add-Content -LiteralPath $LogFile -Value "$(Get-TimeStamp) $content" -Encoding utf8
    }
}
