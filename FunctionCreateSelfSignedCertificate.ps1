Function FunctionCreateSelfSignedCertificate {
    <#
    .SYNOPSIS
        This function will create a self-signed certificate and place it in the "Cert:\CurrentUser\My\" CertStoreLocation and return CertificateThumbprint 
    .EXAMPLE
        $CertificateThumbprint = FunctionCreateSelfSignedCertificate -DnsName $DnsName -FriendlyName $FriendlyName -ExpirationInYears $ExpirationInYears -CerOutputPath $CerOutputPath
    #>
    Param (
        [Parameter(Mandatory=$true)][string]$DnsName ,            
        [Parameter(Mandatory=$true)][string]$FriendlyName ,
        [Parameter(Mandatory=$true)][int]$ExpirationInYears ,
        [Parameter(Mandatory=$true)][string]$CerOutputPath
        )
    #region - Static Variable(s)
    $CertStoreLocation = "Cert:\CurrentUser\My\" # What cert store you want it to be in
    $NotAfter = (Get-Date).AddYears($ExpirationInYears) # Expiration date of the new certificate
    #endregion - Static Variable(s)
    #region - Create hash table "splat" for New-SelfSignedCertificate parameters
    $SelfSignedCertificateSplat = @{
        FriendlyName      = $FriendlyName
        DnsName           = $DnsName
        CertStoreLocation = $CertStoreLocation
        NotAfter          = $NotAfter
        KeyExportPolicy   = "Exportable"
        KeySpec           = "Signature"
        Provider          = "Microsoft Enhanced RSA and AES Cryptographic Provider"
        HashAlgorithm     = "SHA512"
    }
    #endregion -  Create hash table "splat" for New-SelfSignedCertificate parameters
    #region - Create & Export Certificate
    $Certificate = New-SelfSignedCertificate @SelfSignedCertificateSplat # Create certificate
    $CertificatePath = Join-Path -Path $CertStoreLocation -ChildPath $Certificate.Thumbprint # Get certificate path
    Export-Certificate -Cert $CertificatePath -FilePath $CerOutputPath | Out-Null # Export certificate without private key
    $CertificateThumbprint = $Certificate.Thumbprint
    #endregion - Create & Export Certificate
    #region - Return
    Write-Host $CertificateThumbprint -ForegroundColor Yellow
    return $CertificateThumbprint
    #endregion - Return
}