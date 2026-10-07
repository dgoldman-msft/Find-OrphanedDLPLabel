$internalFunctions = Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'internal\functions') -Filter '*.ps1' -File
foreach ($functionFile in $internalFunctions) {
    . $functionFile.FullName
}

. (Join-Path $PSScriptRoot 'functions\Find-OrphanedDLPLabel.ps1')

Export-ModuleMember -Function 'Find-OrphanedDLPLabel'
