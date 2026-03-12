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
    param(
    # The URL that may contain JSON-LD data
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [Alias('href')]
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

    # If set, will force the request to be made even if the URL has already been cached.
    [switch]
    $Force
    )

    begin {
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
        }
    }

    process {        
        $restResponse = 
            if ($Force -or -not $script:Cache[$url]) {
                $script:Cache[$url] = Invoke-RestMethod -Uri $Url
                $script:Cache[$url]
            } else {
                $script:Cache[$url]
            }

        if ($as -eq 'html') {
            return $restResponse
        }
        
        
        # Find all linked data tags within the response
        foreach ($match in $linkedDataRegex.Matches("$restResponse")) {
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
            foreach ($jsonObject in 
                $match.Groups['JsonContent'].Value | 
                    ConvertFrom-Json
            ) {
                # If there was a `@type` property
                if ($jsonObject.'@type') {
                    # all we need to do is decorate the object
                    # If we combine the `@context` and `@type` property, we should have a schema url 
                    $schemaType = $jsonObject.'@context',$jsonObject.'@type' -ne '' -join '/'
                    # and we can make that the typename
                    $jsonObject.pstypenames.insert(0, $schemaType)
                    # and show the object.
                    $jsonObject
                }
                # If there was a `@graph` property
                elseif ($jsonObject.'@graph') {
                    # we can display all items in the graph
                    foreach ($graphObject in $jsonObject.'@graph') {
                        # each of them will tell us it's `@type`
                        if ($graphObject.'@type') {
                            # and we can decorate each object appropriately
                            $graphObject.pstypenames.insert(0, $graphObject.'@type')
                        }
                        $graphObject
                    }                    
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
