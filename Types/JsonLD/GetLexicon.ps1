
param($graph = $this)

$jsonSchema = $this.GetJsonSchema($graph)
if (-not $jsonSchema.'$id') {
    throw "Missing $jsonSchema.$id"
    return
}

$domain, $relativePath = $jsonSchema.'$id' -replace '^$' -split '/'
if (-not $domain) { return}
if (-not $relativePath ) { return }
$domain = @($domain -split '\.')
[Array]::Reverse($domain)
$nsid = $domain, $relativePath -join '.'


$jsonSchema.psobject.properties.Remove('$id')

[Ordered]@{
    lexicon = 1
    id = $nsid
    defs = [Ordered]@{
        main = [Ordered]@{
            type = 'record'
            description = $jsonSchema.description
            record = $jsonSchema
        }
    }
}


