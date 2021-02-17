Function Get-SelfSignedCertificate {
    <#
    .SYNOPSIS
        This function will create a self-signed certificate and place it in the "Cert:\CurrentUser\My\" CertStoreLocation and return CertificateThumbprint 
    .EXAMPLE
        $CertificateThumbprint = FunctionCreateSelfSignedCertificate -DnsName $DnsName -FriendlyName $FriendlyName -ExpirationInYears $ExpirationInYears -CerOutputPath $CerOutputPath
    .INPUTS
        string, int
    .OUTPUTS
        string (CertificateThumbprint), certificate file with or without private key
    .NOTES
        Author:  Jim B.
        Website: https://github.com/jbienstman            
    #>
    Param (
        [Parameter(Mandatory=$true)][string]$DnsName ,            
        [Parameter(Mandatory=$true)][string]$FriendlyName ,
        [Parameter(Mandatory=$true)][int]$ExpirationInYears ,
        [Parameter(Mandatory=$true)][string]$CerOutputPath ,
        [Parameter(Mandatory=$false)][string]$HashAlgorithm = "SHA512" ,
        [Parameter(Mandatory=$false)][string]$exportPrivateKey = $false
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
        HashAlgorithm     = $HashAlgorithm
    }
    #endregion -  Create hash table "splat" for New-SelfSignedCertificate parameters
    #region - Create & Export Certificate
    $Certificate = New-SelfSignedCertificate @SelfSignedCertificateSplat # Create certificate
    $CertificateThumbprint = $Certificate.Thumbprint
    $CertificatePath = Join-Path -Path $CertStoreLocation -ChildPath $CertificateThumbprint # Get certificate path
    if ($exportPrivateKey)
        {
        $passwordString = Read-Host ("Please a new password for exporting the private key")
        $securePasswordString = ConvertTo-SecureString -String $passwordString -Force -AsPlainText
        Export-PfxCertificate -Cert $CertificatePath -FilePath $CerOutputPath -Password $securePasswordString | Out-Null # Export certificate without private key
        }
    else
        {
        Export-Certificate -Cert $CertificatePath -FilePath $CerOutputPath | Out-Null # Export certificate without private key
        }
    
    #endregion - Create & Export Certificate
    #region - Return
    Write-Host $CertificateThumbprint -ForegroundColor Yellow
    return $CertificateThumbprint
    #endregion - Return
}