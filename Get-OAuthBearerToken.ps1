Function Get-OAuthBearerToken {
    <#
    .SYNOPSIS
        This function use a certificate to connect to 'https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token' using OAuth to an
        existing "App Registration" in M365, then builds and returns a OAuth Bearer Access Token for use with $Scope (.default API Endpoint)
        When connecting to the $Scope API presenting the OAuth Bearer Token, you will act as the App Registration with all pre-defined API permissions.

        NOTE: When "useCertificateFullFilePath" parameter set is used, you need to provide a full path to a ".pfx" certificate file (incl. Private Key)
        accessible by the account running the script, ("c:\temp\certificatename.pfx"), unless you provide a secure string for the $pfxPasswordSecure parameter,
        you will be prompted for the private key password interactively.

        NOTE: When "useCertificateThumbprint" parameter set is used, you need to provide the thumbprint of a certificate which is already installed
        in your personal certificate store (Cert:\CurrentUser\My\THUMBPRINT)

    .EXAMPLE
        $CertificateFullFilePath = "c:\foldername\certificatename.pfx"
        Get-OAuthBearerToken -Scope $Scope -TenantId $TenantId -ClientId $ClientId -useCertificateFullFilePath $CertificateFullFilePath
    .EXAMPLE
        $CertificateThumbprint = "ABCDEF0123456789ABCDEF0123456789ABCDEF01"
        Get-OAuthBearerToken -Scope $Scope -TenantId $TenantId -ClientId $ClientId -useCertificateThumbprint $CertificateThumbprint
    .INPUTS
        string, switch
    .OUTPUTS
        string
    .NOTES
        Author:  Jim B.
        Website: https://github.com/jbienstman
    #>
    [CmdletBinding(DefaultParameterSetName = 'useCertificateFullFilePath')]
    Param (
        [Parameter(Mandatory = $false, ParameterSetName = 'useCertificateThumbprint')]
        [Parameter(Mandatory = $false, ParameterSetName = 'useCertificateFullFilePath')][string]$Scope = "https://graph.microsoft.com/.default",
        #
        [Parameter(Mandatory = $true, ParameterSetName = 'useCertificateThumbprint')]
        [Parameter(Mandatory = $true, ParameterSetName = 'useCertificateFullFilePath')][string]$TenantId ,
        #
        [Parameter(Mandatory = $true, ParameterSetName = 'useCertificateThumbprint')]
        [Parameter(Mandatory = $true, ParameterSetName = 'useCertificateFullFilePath')][string]$ClientId ,
        #
        [Parameter(Mandatory = $true, ParameterSetName = 'useCertificateThumbprint')][string]$useCertificateThumbprint,
        #
        [Parameter(Mandatory = $true, ParameterSetName = 'useCertificateFullFilePath')][string]$useCertificateFullFilePath ,
        [Parameter(Mandatory = $false, ParameterSetName = 'useCertificateFullFilePath')][SecureString]$pfxPasswordSecure ,
        #
        [Parameter(Mandatory = $false, ParameterSetName = 'useCertificateThumbprint')]
        [Parameter(Mandatory = $false, ParameterSetName = 'useCertificateFullFilePath')][bool]$returnHeaders = $false
        )
    #region - Create base64 hash of certificate
    if ($useCertificateThumbprint)
        {
        $Certificate = Get-Item Cert:\CurrentUser\My\$useCertificateThumbprint
        }
    else
        {
            if ($pfxPasswordSecure)
                {
                    $Certificate = Get-PfxCertificate -FilePath $useCertificateFullFilePath -Password $pfxPasswordSecure #must be a secure string
                }
            else
                {
                    $Certificate = Get-PfxCertificate -FilePath $useCertificateFullFilePath #will prompt for password
                }
        }
    $CertificateBase64Hash = [System.Convert]::ToBase64String($Certificate.GetCertHash())
    #endregion - Create base64 hash of certificate
    #region - JWT Token
    #region - Create JWT timestamp for expiration
    $StartDate = (Get-Date "1970-01-01T00:00:00Z" ).ToUniversalTime()
    $JWTExpirationTimeSpan = (New-TimeSpan -Start $StartDate -End (Get-Date).ToUniversalTime().AddMinutes(2)).TotalSeconds
    $JWTExpiration = [math]::Round($JWTExpirationTimeSpan,0)
    #endregion - Create JWT timestamp for expiration
    #region - Create JWT validity start timestamp
    $NotBeforeExpirationTimeSpan = (New-TimeSpan -Start $StartDate -End ((Get-Date).ToUniversalTime())).TotalSeconds
    $NotBefore = [math]::Round($NotBeforeExpirationTimeSpan,0)
    #endregion - Create JWT validity start timestamp
    #region - Create JWT header
    $JWTHeader = @{
        alg = "RS256"
        typ = "JWT"
        # Use the CertificateBase64Hash and replace/strip to match web encoding of base64
        x5t = $CertificateBase64Hash -replace '\+','-' -replace '/','_' -replace '='
    }
    #endregion - Create JWT header
    #region - Create JWT payload
    $JWTPayLoad = @{
        # What endpoint is allowed to use this JWT
        aud = "https://login.microsoftonline.com/$TenantId/oauth2/token"
        # Expiration timestamp
        exp = $JWTExpiration
        # Issuer = your application
        iss = $ClientId
        # JWT ID: random guid
        jti = [guid]::NewGuid()
        # Not to be used before
        nbf = $NotBefore
        # JWT Subject
        sub = $ClientId
    }
    #endregion - Create JWT payload
    #region - Convert header and payload to base64
    $JWTHeaderToByte = [System.Text.Encoding]::UTF8.GetBytes(($JWTHeader | ConvertTo-Json))
    $EncodedHeader = [System.Convert]::ToBase64String($JWTHeaderToByte)
    #
    $JWTPayLoadToByte =  [System.Text.Encoding]::UTF8.GetBytes(($JWTPayload | ConvertTo-Json))
    $EncodedPayload = [System.Convert]::ToBase64String($JWTPayLoadToByte)
    #endregion - Convert header and payload to base64
    #region - Join header and Payload with "." to create a valid (unsigned) JWT
    $JWT = $EncodedHeader + "." + $EncodedPayload
    #endregion - Join header and Payload with "." to create a valid (unsigned) JWT
    #region - Get the private key object of your certificate
    $PrivateKey = $Certificate.PrivateKey
    #endregion - Get the private key object of your certificate
    #region - Define RSA signature and hashing algorithm
    $RSAPadding = [Security.Cryptography.RSASignaturePadding]::Pkcs1
    $HashAlgorithm = [Security.Cryptography.HashAlgorithmName]::SHA256
    #endregion - Define RSA signature and hashing algorithm
    #region - Create a signature of the JWT
    $Signature = [Convert]::ToBase64String(
        $PrivateKey.SignData([System.Text.Encoding]::UTF8.GetBytes($JWT),$HashAlgorithm,$RSAPadding)
    ) -replace '\+','-' -replace '/','_' -replace '='
    #endregion - Create a signature of the JWT
    #region - Join the signature to the JWT with "."
    $JWT = $JWT + "." + $Signature
    #endregion - Join the signature to the JWT with "."
    #endregion - JWT Token
    #region - Create hash table "splat" for body parameters
    $Body = @{
        client_id = $ClientId
        scope = $Scope
        client_assertion = $JWT
        client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
        grant_type = "client_credentials"
        }
    #endregion - Create hash table "splat" for body parameters
    #region - Use the self-generated JWT as Authorization
    $Header = @{Authorization = "Bearer $JWT"}
    #endregion - Use the self-generated JWT as Authorization
    #region - Create hash table "splat" for Invoke-Restmethod
    $Uri = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
    $restMethodSplat = @{
        ContentType = 'application/x-www-form-urlencoded'
        Method = 'POST'
        Uri = $Uri
        Body = $Body
        Headers = $Header
        }
    #endregion - Create hash table "splat" for Invoke-Restmethod
    #region - Invoke RESTMethod
    $BearerToken = Invoke-RestMethod @restMethodSplat
    #endregion - Invoke RESTMethod
    #region - Return
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
        return $BearerToken
        }
    #endregion - Return
}
