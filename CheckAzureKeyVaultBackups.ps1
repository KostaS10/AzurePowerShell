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

$date30daysago = (Get-Date).AddDays(-30).ToString("yyyy-MM-dd")

#Check KeyVault keys and remove older than 30 days
Get-AzStorageBlob -Container keyvaultkeybackups -Context $context | sort LastModified | where{$_.LastModified -lt $date30daysago} | Remove-AzStorageBlob

#Check KeyVault secrets and remove older than 30 days
Get-AzStorageBlob -Container keyvaultsecretbackups -Context $context | sort LastModified | where{$_.LastModified -lt $date30daysago} | Remove-AzStorageBlob

#Check KeyVault secrets and remove older than 30 days
Get-AzStorageBlob -Container keyvaultcertificatebackups -Context $context | sort LastModified | where{$_.LastModified -lt $date30daysago} | Remove-AzStorageBlob

}
catch
{
    $message = $_.Exception.Message
    Write-Output $message
    throw $message
}
