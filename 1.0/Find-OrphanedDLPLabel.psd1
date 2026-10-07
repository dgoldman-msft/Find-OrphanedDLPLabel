@{
    RootModule        = 'Find-OrphanedDLPLabel.psm1'
    ModuleVersion     = '1.0'
    GUID              = 'e3b49ab7-2dd3-42fd-bd25-c75c6beb157e'
    Author            = 'Dave Goldman'
    Copyright         = '(c) 2026 Dave Goldman. All rights reserved.'
    Description       = 'Investigates Microsoft Purview sensitivity-label GUIDs across the label catalog, auto-labeling rules, DLP rules, audit records, and optional Compliance Search results.'
    PowerShellVersion = '7.1'
    FunctionsToExport = @('Find-OrphanedDLPLabel')
    FormatsToProcess   = @('Find-OrphanedDLPLabel.Format.ps1xml')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags       = @('M365', 'Purview', 'DLP', 'SensitivityLabel', 'Compliance', 'Audit')
            ProjectUri = 'https://github.com/dgoldman-msft/Find-OrphanedDLPLabel'
            LicenseUri = 'https://github.com/dgoldman-msft/Find-OrphanedDLPLabel/blob/main/LICENSE'
        }
    }
}
