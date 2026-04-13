function Get-JsonLD {
    <#
    .SYNOPSIS
        Gets JSON-LD data from a given URL.
    .DESCRIPTION
        Gets JSON Linked Data from a given URL.
        
        This is a format used by many websites to provide structured data about their content.
    .EXAMPLE
        # Want to get information about a movie?  Linked Data to the rescue!
        Get-JsonLD -Url https://letterboxd.com/film/amelie/
    .EXAMPLE
        # Want information about an article?  Lots of news sites use this format.
        Get-JsonLD https://www.thebulwark.com/p/mahmoud-khalil-immigration-detention-first-amendment-free-speech-rights    
    .EXAMPLE
        # Want to get information about a schema?
        jsonld https://schema.org/Movie
        # Get-JSONLD will output the contents of a `@Graph` object if no `@type` is found.        
    #>
    [Alias('jsonLD','json-ld')]
    [CmdletBinding()]
    param(
    # The URL that may contain JSON-LD data
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [Alias('href', 'Uri')]
    [Uri]
    $Url,

    <#
    
    If set, will the output as:

    |as|is|
    |-|-|
    |html|the response as text|
    |json|the match as json|
    |*jsonld`|ld`|linkedData*|the match as linked data|'
    |script|the script tag|
    |xml|the script tag, as xml|
    
    #>    
    [ValidateSet('html', 'json', 'jsonld', 'ld', 'linkedData', 'script', 'xml')]
    [string]
    $as = 'jsonld',

    [switch]
    $RawHtml,

    # If set, bypasses certificate validation for HTTPS requests.
    [switch]
    $SkipCertificateCheck,

    # Authentication mechanism to pass directly to Invoke-RestMethod.
    [Microsoft.PowerShell.Commands.WebAuthenticationType]
    $Authentication,

    # User agent string to pass directly to Invoke-RestMethod.
    [string]
    $UserAgent,

    # Headers to pass directly to Invoke-RestMethod.
    [Collections.IDictionary]
    $Headers,

    # If set, ignores the cached response and forces a fresh request.
    [switch]
    $IgnoreCache,

    # If set, will force the request to be made even if the URL has already been cached.
    [switch]
    $Force
    )

    begin {
        Write-Verbose "Initializing Get-JsonLD"

        # Create a pattern to match the JSON-LD script tag
        $linkedDataRegex = [Regex]::new(@'
(?<HTML_LinkedData>
<script                                       # Match <script tag
\s{1,}                                        # Then whitespace
type=                                         # Then the type= attribute (this regex will only match if it is first)
[\"\']                                        # Double or Single Quotes
application/ld\+json                          # The type that indicates linked data
[\"\']                                        # Double or Single Quotes
[^>]{0,}                                      # Match anything until the end of the start tag
\>                                            # Match the end of the start tag
(?<JsonContent>(?:.|\s){0,}?(?=\z|</script>)) # Anything until the end tag is JSONContent
)        
'@, 'IgnoreCase,IgnorePatternWhitespace','00:00:00.1')

        # Initialize the cache for JSON-LD requests
        if (-not $script:Cache) {
            $script:Cache = [Ordered]@{}
            Write-Debug "Initialized JSON-LD cache store"
        }

        filter output {
            $in = $_
            $shouldOutput = $true
            if ($in.'@context' -is [string]) {
                $context  = $in.'@context'
            }
            if ($in.'@graph') {
                if ($in.pstypenames -ne 'application/ld+json') {
                    $in.pstypenames.insert(0,'application/ld+json')
                }
                foreach ($graphObject in $in.'@graph') {
                    $graphObject | output
                }
                # Emit graph entries instead of the wrapper document.
                $shouldOutput = $false
            }
            elseif ($in.'@type') {

                $typeName = if ($context) {
                    $context, $in.'@type' -join '/'
                } else {
                    $in.'@type'
                }

                if ($in.pstypenames -ne 'application/ld+json') {
                    $in.pstypenames.insert(0,'application/ld+json')
                }
                if ($in.pstypenames -ne $typeName) {
                    $in.pstypenames.insert(0,$typeName)
                }

                foreach ($property in $in.psobject.properties) {
                    if ($property.value.'@type') {
                        $null = $property.value | output
                    }
                }
            }

            if ($shouldOutput) {
                $in
            }
        }

        $foreachFile = {
            $inFile = $_.FullName
            try {
                Write-Verbose "Reading JSON-LD from file: $inFile"
                
                Get-Content -LiteralPath $_.FullName -Raw | 
                    ConvertFrom-Json |
                        output
            } catch {
                Write-Warning "Could not parse JSON-LD content from file: $inFile"
                Write-Debug "File parse error for '$inFile': $($_.Exception.Message)"
            }
        }
    }

    process {        
        Write-Verbose "Processing URL: $Url"

        $isJsonLdObject = {
            param($InputObject)
            if (-not $InputObject) { return $false }

            $propertyNames = @($InputObject.psobject.properties.Name)
            ($propertyNames -contains '@context') -or
            ($propertyNames -contains '@type') -or
            ($propertyNames -contains '@graph')
        }

        if ($url.IsFile -or 
            -not $url.AbsoluteUri
        ) {
            if (Test-Path $url.OriginalString) {
                Write-Verbose "Reading JSON-LD from local path: $($url.OriginalString)"
                Get-ChildItem $url.OriginalString -File |
                    Foreach-Object $foreachFile
            } elseif ($MyInvocation.MyCommand.Module -and 
                (Test-Path (
                    Join-Path (
                        $MyInvocation.MyCommand.Module | Split-Path
                    ) $url.OriginalString
                ))
            ) {
                Write-Verbose "Reading JSON-LD from module-relative path: $($url.OriginalString)"
                Get-ChildItem -Path (
                    Join-Path (
                        $MyInvocation.MyCommand.Module | Split-Path
                    ) $url.OriginalString  
                ) -File |
                    Foreach-Object $foreachFile
            } else {
                Write-Warning "Path not found for URL/file input: $($url.OriginalString)"
            }
            
            return
        }
            
        $invokeRestMethodSplat = @{ Uri = $Url }
        if ($PSBoundParameters.ContainsKey('SkipCertificateCheck')) {
            $invokeRestMethodSplat.SkipCertificateCheck = $SkipCertificateCheck
        }
        if ($PSBoundParameters.ContainsKey('Authentication')) {
            $invokeRestMethodSplat.Authentication = $Authentication
        }
        if ($PSBoundParameters.ContainsKey('UserAgent')) {
            $invokeRestMethodSplat.UserAgent = $UserAgent
        }
        if ($PSBoundParameters.ContainsKey('Headers')) {
            $invokeRestMethodSplat.Headers = $Headers
        }

        Write-Debug ("Invoke-RestMethod parameter keys: {0}" -f (($invokeRestMethodSplat.Keys | Sort-Object) -join ', '))

        try {
            $restResponse = 
                if ($Force -or $IgnoreCache -or -not $script:Cache[$url]) {
                    Write-Verbose "Fetching fresh response from remote URL"
                    $script:Cache[$url] = Invoke-RestMethod @invokeRestMethodSplat
                    $script:Cache[$url]
                } else {
                    Write-Verbose "Using cached response"
                    $script:Cache[$url]
                }
        }
        catch {
            Write-Error -Message "Failed to retrieve JSON-LD from '$Url'. $($_.Exception.Message)" -ErrorRecord $_
            return
        }

        if ($as -eq 'html') {
            Write-Debug "Returning raw HTML response"
            return $restResponse
        }

        # Handle API responses where the body is already JSON-LD (not embedded in HTML).
        if (& $isJsonLdObject $restResponse) {
            Write-Verbose "Detected direct JSON-LD object response"

            if ($As -eq 'xml') {
                Write-Warning "XML output is not available for direct JSON-LD API responses; returning JSON instead"
                return $restResponse | ConvertTo-Json -Depth 100
            }

            if ($As -eq 'script') {
                Write-Warning "Script output is not available for direct JSON-LD API responses; returning JSON instead"
                return $restResponse | ConvertTo-Json -Depth 100
            }

            if ($As -eq 'json') {
                return $restResponse | ConvertTo-Json -Depth 100
            }

            $jsonLdObjects = if ($restResponse -is [System.Collections.IEnumerable] -and -not ($restResponse -is [string])) {
                @($restResponse)
            } else {
                @($restResponse)
            }

            foreach ($jsonObject in $jsonLdObjects) {
                if ($jsonObject.'@type' -or $jsonObject.'@graph') {
                    $jsonObject | output
                } else {
                    $jsonObject
                }
            }

            return
        }

        # Some servers return JSON-LD as plain text; try parsing it before HTML script-tag extraction.
        if ($restResponse -is [string]) {
            try {
                $parsedJson = $restResponse | ConvertFrom-Json -ErrorAction Stop
                if (& $isJsonLdObject $parsedJson) {
                    Write-Verbose "Detected direct JSON-LD text response"

                    if ($As -eq 'xml') {
                        Write-Warning "XML output is not available for direct JSON-LD API responses; returning JSON instead"
                        return $parsedJson | ConvertTo-Json -Depth 100
                    }

                    if ($As -eq 'script') {
                        Write-Warning "Script output is not available for direct JSON-LD API responses; returning JSON instead"
                        return $parsedJson | ConvertTo-Json -Depth 100
                    }

                    if ($As -eq 'json') {
                        return $parsedJson | ConvertTo-Json -Depth 100
                    }

                    foreach ($jsonObject in @($parsedJson)) {
                        if ($jsonObject.'@type' -or $jsonObject.'@graph') {
                            $jsonObject | output
                        } else {
                            $jsonObject
                        }
                    }

                    return
                }
            }
            catch {
                Write-Debug "Response was not parseable as direct JSON-LD text; trying HTML script-tag extraction"
            }
        }
        
        # Find all linked data tags within the response
        $linkedDataMatches = $linkedDataRegex.Matches("$restResponse")
        Write-Debug "Linked data script tags found: $($linkedDataMatches.Count)"

        if (-not $linkedDataMatches.Count) {
            Write-Warning "No JSON-LD script tags were found in response from '$Url'"
        }

        foreach ($match in $linkedDataMatches) {
            # If we want the result as xml
            if ($As -eq 'xml') {
                # try to cast it
                $matchXml ="$match" -as [xml]
                if ($matchXml) {
                    # and output it if found.
                    $matchXml
                    continue
                } else {
                    # otherwise, fall back to the `<script>` tag
                    Write-Warning "Could not cast matched JSON-LD script tag to XML; returning script tag instead"
                    $As = 'script'
                }
            }

            # If we want the tag, that should be the whole match
            if ($As -eq 'script') {
                "$match"
                continue
            }
            
            # If we want it as json, we have a match group.
            if ($As -eq 'json') {
                $match.Groups['JsonContent'].Value
                continue
            }
            # Otherwise, we want it as linked data, so convert from the json
            try {
                $jsonObjects = $match.Groups['JsonContent'].Value | ConvertFrom-Json
            }
            catch {
                Write-Warning "Failed to parse JSON-LD payload from '$Url'"
                Write-Debug "JSON parse error: $($_.Exception.Message)"
                continue
            }

            foreach ($jsonObject in $jsonObjects) {
                # If there was a `@type` or `@graph` property
                if (
                    $jsonObject.'@type' -or 
                    $jsonObject.'@graph'
                ) {
                    # output the object as jsonld
                    $jsonObject | output
                    continue                    
                }                
                # If there is neither a `@type` or a `@graph`
                else {
                    # just output the object.
                    $jsonObject
                }                
            }
        }        
    }
}
