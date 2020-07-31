#Backup AzureKeyVault
Import-Module Az.Accounts
Import-Module Az.Automation
Import-Module Az.Storage
Import-Module Az.KeyVault
$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName       
    "Logging in to Azure..."
    Connect-AzAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

try
{
#List keyvaults
$keyvaults = (Get-AzKeyVault).VaultName

Write-Output $keyvaults

#Set storage context and date

$sastoken = Get-AutomationVariable -Name "STGSASToken"
$context = New-AzStorageContext -StorageAccountName $stgaccname -SasToken $sastoken
$date = (Get-Date).ToString("yyyy-MM-dd")

Write-Output $date

#Backup KeyVault keys
foreach($keyvault in $keyvaults){
    $keys = Get-AzKeyVaultKey -VaultName $keyvault
    
    foreach($key in $keys){
        $keyname = $key.Name
        Backup-AzKeyVaultKey -VaultName $keyvault -Name $keyname -OutputFile ("$env:TEMP\$keyname" + "-key.backup")
    }
}

$keynames = (Get-AzKeyVaultKey -VaultName $keyvault).Name | Out-File "$env:TEMP\keynames.txt"
$files = Get-ChildItem $env:TEMP | where{$_.Name -like "*-key*" -or $_.Name -like "*keynames*"}

Write-Output $files


foreach($file in $files){
    Set-AzStorageBlobContent -Context $context -Container "keyvaultkeybackups" -File "$env:TEMP\$file" -Blob "$date\$file" -Force
}

#Backup KeyVault secrets

foreach($keyvault in $keyvaults){
    $secrets = Get-AzKeyVaultSecret -VaultName $keyvault
    
    foreach($secret in $secrets){
        $secretname = $secret.Name
        Backup-AzKeyVaultSecret -VaultName $keyvault -Name $secretname -OutputFile ("$env:TEMP\$secretname" + "-secret.backup")
    }
}

$secretnames = (Get-AzKeyVaultSecret -VaultName $keyvault).Name | Out-File "$env:TEMP\secretnames.txt"
$files = Get-ChildItem $env:TEMP | where{$_.Name -like "*-secret*" -or $_.Name -like "*secretnames*"}

Write-Output $files


foreach($file in $files){
    Set-AzStorageBlobContent -Context $context -Container "keyvaultsecretbackups" -File "$env:TEMP\$file" -Blob "$date\$file" -Force
}

#Backup KeyVault certificates

foreach($keyvault in $keyvaults){
    $certificates = Get-AzKeyVaultCertificate -VaultName $keyvault
    
    foreach($certificate in $certificates){
        $certificatename = $certificate.Name
        Backup-AzKeyVaultCertificate -VaultName $keyvault -Name $certificatename -OutputFile ("$env:TEMP\$certificatename" + "-certificate.backup")
    }
}

$certificatenames = (Get-AzKeyVaultCertificate -VaultName $keyvault).Name | Out-File "$env:TEMP\certificatenames.txt"
$files = Get-ChildItem $env:TEMP | where{$_.Name -like "*-certificate*" -or $_.Name -like "*certificatenames*"}

Write-Output $files


foreach($file in $files){
    Set-AzStorageBlobContent -Context $context -Container "keyvaultcertificatebackups" -File "$env:TEMP\$file" -Blob "$date\$file" -Force
}



}
catch
{
    $message = $_.Exception.Message
    Write-Output $message
    throw $message
}
