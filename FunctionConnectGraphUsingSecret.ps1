Function FunctionConnectGraphUsingSecret {
    <#
    .SYNOPSIS
        This function will connect to GRAPH API scope using a "Secret" and returns Headers for use with Invoke-RestMethod Token - requires: TenantId, ClientId & ClientSecret
    .EXAMPLE
        $Headers = FunctionConnectGraphUsingSecret -TenantId 'GUID' -ClientId 'GUID' -ClientSecret 'SECRETPASSWORD'
    #>
    Param (
        [Parameter(Mandatory=$true)][string]$TenantId ,    
        [Parameter(Mandatory=$true)][string]$ClientId ,
        [Parameter(Mandatory=$true)][string]$ClientSecret 
        )
    #region - Static Variable(s)
    $Scope = "https://graph.microsoft.com/.default"
    #endregion - Static Variable(s)
    #region - Create hash table "splat" for body parameters
    $Body = @{
            client_id     = $ClientId
            scope         = $Scope
            client_secret = $ClientSecret
            grant_type    = "client_credentials"
            }
    #endregion - Create hash table "splat" for body parameters
    #region - Create hash table "splat" for Invoke-WebRequest
    $Uri = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
    $webRequestSplat = @{
        ContentType = 'application/x-www-form-urlencoded'    
        Method = 'POST'
        Uri = $Uri
        Body = $Body
        UseBasicParsing = $true
        }
    #endregion - Create hash table "splat" for Invoke-WebRequest
    #region - Invoke-WebRequest
    $BearerToken = ((Invoke-WebRequest @webRequestSplat).Content | ConvertFrom-Json)
    #endregion - Invoke-WebRequest
    #region - Use BearerToken to build Headers for Invoke-RestMethod
    $access_token = $BearerToken.access_token
    $token_type = $BearerToken.token_type
    $Headers = @{Authorization = "$token_type $access_token"}
    #endregion - Use BearerToken to build Headers for Invoke-RestMethod    
    #region - Return Bearer Token 
    return $Headers
    #endregion - Return Bearer Token 
}