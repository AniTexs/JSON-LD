Please:

* [Like, Share, and Subscribe](https://github.com/PowerShellWeb/JSON-LD)
* [Support Us](https://github.com/sponsors/StartAutomating)

---

## JSON-LD 0.1.1.1 - Pull Request

* Enhanced `Get-JsonLD` web request options
  * Added `-SkipCertificateCheck` passthrough to `Invoke-RestMethod`
  * Added `-Authentication` passthrough to `Invoke-RestMethod`
  * Added `-UserAgent` passthrough to `Invoke-RestMethod`
  * Added `-Headers` passthrough to `Invoke-RestMethod`
* Added `-IgnoreCache` switch to bypass cached responses and force a fresh request
* Added `Write-Verbose`, `Write-Debug`, and `Write-Warning` output throughout for improved diagnostics
* Added error handling with `try/catch` around web requests and JSON parsing
* Fixed output formatting for direct JSON-LD API responses (true `application/ld+json` endpoints)
  * `@graph` document responses now emit individual graph entities rather than the wrapper object
  * Direct JSON-LD object and JSON-text responses are detected and processed without requiring HTML script-tag extraction

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

## JSON-LD 0.1

Caching JSON-LD requests

---

## JSON-LD 0.0.1

Get Linked Data from any page

* Initial Release of JSON-LD Module (#1)
  * `Get-JsonLD` gets linked data (#2)
  * `Get-JsonLD` is aliased to `jsonLD` and `json-ld`
