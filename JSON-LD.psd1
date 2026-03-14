@{
    RootModule = 'JSON-LD.psm1'
    ModuleVersion = '0.1.1'
    GUID = '4e65477c-012c-4077-87c7-3e07964636ce'
    Author = 'James Brundage'
    CompanyName = 'Start-Automating'
    Copyright = '(c) 2025-2026 Start-Automating.'
    Description = 'Get JSON Linked Data with PowerShell'
    FunctionsToExport = 'Get-JsonLD'
    AliasesToExport = 'jsonLD', 'json-ld'
    TypesToProcess = 'JSON-LD.types.ps1xml'
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('json-ld','SEO','Web','PoshWeb','LinkedData','schema.org')
            # A URL to the license for this module.
            ProjectURI = 'https://github.com/PoshWeb/JSON-LD'
            LicenseURI = 'https://github.com/PoshWeb/JSON-LD/blob/main/LICENSE'
            ReleaseNotes = @'
---

## JSON-LD 0.1.1

* Updating Examples (#13)
* Simplfiying module scaffolding (#15)
* Building types with EZOut (#5)
* Supporting file input (#23)
* `Get-JSONLD -as`
  * `Get-JSONLD -as json` (#16)
  * `Get-JSONLD -as html` (#17)
  * `Get-JSONLD -as script` (#18)
  * `Get-JSONLD -as xml` (#19)
* Adding conversion to JsonSchema (#21)
* Adding conversion to At Protocol Lexicons (#22)

---

Please:

* [Like, Share, and Subscribe](https://github.com/PowerShellWeb/JSON-LD)
* [Support Us](https://github.com/sponsors/StartAutomating)

Additional History in [CHANGELOG](https://github.com/PoshWeb/JSON-LD/blob/main/CHANGELOG.md)
'@
        }
    }
    
}

