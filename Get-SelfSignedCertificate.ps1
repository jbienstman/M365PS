Function Get-SelfSignedCertificate {
    <#
    .SYNOPSIS
        This function will create a self-signed certificate, register the certificate in the CertStoreLocation (default: "Cert:\CurrentUser\My\") and return CertificateThumbprint string
    .EXAMPLE
        $CertificateThumbprint = Get-SelfSignedCertificate -DnsName $DnsName -FriendlyName $FriendlyName -ExpirationInYears $ExpirationInYears -CerOutputPath $CerOutputPath -HashAlgorithm $HashAlgorithm -exportPrivateKey:$true -privateKeyPassword $privateKeyPassword
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
        [Parameter(Mandatory=$false)][bool]$exportPrivateKey = $false ,
        [Parameter(Mandatory=$false)][string]$CertStoreLocation = "Cert:\CurrentUser\My\" , # What cert store you want it to be in
        [Parameter(Mandatory=$false)][string]$privateKeyPassword ,
        [Parameter(Mandatory=$false)][bool]$allowFriendlyNameDuplicates = $false ,
        [Parameter(Mandatory=$false)][bool]$savePrivateKeyPasswordTxtFile = $true
        )
    #region - Check if Friendly Name already exists in $CertStoreLocation
    if ($allowFriendlyNameDuplicates -eq $false)
        {
        $friendlyNameMatches = Get-ChildItem $CertStoreLocation | Where-Object { $_.FriendlyName -eq $FriendlyName }
        if ($friendlyNameMatches.Count -gt 0)
            {
            Write-Host ("The certificate friendly name is already present in: " + $CertStoreLocation) -ForegroundColor Red
            $friendlyNameMatches | Format-Table ThumbPrint, Subject, FriendlyName
            exit
            }
        }
    #endregion - Check if Friendly Name already exists in $CertStoreLocation
    #region - Create hash table "splat" for New-SelfSignedCertificate parameters
    $NotAfter = (Get-Date).AddYears($ExpirationInYears) # Expiration date of the new certificate
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
    $Certificate = New-SelfSignedCertificate @SelfSignedCertificateSplat # Create certificate & register in certificate store
    $CertificateThumbprint = $Certificate.Thumbprint
    $CertificatePath = Join-Path -Path $CertStoreLocation -ChildPath $CertificateThumbprint # Get certificate path
    $pfxFilePath = ($CerOutputPath.TrimEnd("\") + "\" + $FriendlyName + ".pfx")
    $cerFilePath = ($CerOutputPath.TrimEnd("\") + "\" + $FriendlyName + ".cer")
    $cpwFilePath = ($CerOutputPath.TrimEnd("\") + "\" + $FriendlyName + ".txt")
    if ($exportPrivateKey)
        {
        if ($privateKeyPassword -eq "" -or $null -eq $privateKeyPassword)
            {
            $passwordString = Read-Host ("Please enter a password for exporting the private key")
            $securePasswordString = ConvertTo-SecureString -String $passwordString -Force -AsPlainText
            }
        else
            {
            $securePasswordString = ConvertTo-SecureString -String $privateKeyPassword -Force -AsPlainText
            }
        Export-PfxCertificate -Cert $CertificatePath -FilePath $pfxFilePath -Password $securePasswordString | Out-Null # Export certificate WITH private key
        Export-Certificate -Cert $CertificatePath -FilePath $cerFilePath | Out-Null # Export certificate without private key
        }
    else
        {
        Export-Certificate -Cert $CertificatePath -FilePath $cerFilePath | Out-Null # Export certificate without private key
        }
    if ($savePrivateKeyPasswordTxtFile)
        {
        $privateKeyPassword | Out-File -LiteralPath $cpwFilePath -Encoding utf8 -Force
        }
    #endregion - Create & Export Certificate
    #region - Return
    return $CertificateThumbprint
    #endregion - Return
}