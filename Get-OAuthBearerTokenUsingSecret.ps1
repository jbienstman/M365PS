Function Get-OAuthBearerTokenUsingSecret {
    <#
    .SYNOPSIS
        This function will connect to "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" using a "Secret" (password)
        and returns an OAuth Bearer Token or $Headers that can be used directly with the "Invoke-RestMethod -Headers $Headers" parameter.
    .EXAMPLE
        Get-OAuthBearerTokenUsingSecret -TenantId $TenantId -ClientId $ClientId -ClientSecret $ClientSecret -Scope "https://graph.microsoft.com/.default"
    .INPUTS
        string
    .OUTPUTS
        Hashtable
    .NOTES
        Author:  Jim B.
        Website: https://github.com/jbienstman
    #>
    Param (
        [Parameter(Mandatory=$true)][string]$TenantId ,
        [Parameter(Mandatory=$true)][string]$ClientId ,
        [Parameter(Mandatory=$true)][string]$ClientSecret ,
        [Parameter(Mandatory=$true)][string]$Scope ,
        [Parameter(Mandatory=$false)][bool]$returnHeaders = $false
    )
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
    if ($returnHeaders)
        {
        #region - Use BearerToken to build Headers for Invoke-RestMethod
        $access_token = $BearerToken.access_token
        $token_type = $BearerToken.token_type
        $Headers = @{Authorization = "$token_type $access_token"}
        #endregion - Use BearerToken to build Headers for Invoke-RestMethod
        return $Headers
        }
    else
        {
        return $BearerToken.access_token
        }
    #endregion - Return
}