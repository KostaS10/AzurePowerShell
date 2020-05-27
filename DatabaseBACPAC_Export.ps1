Import-Module Az.KeyVault
Import-Module Az.Sql
Import-Module Az.Accounts

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


$RG = ""
$Server = ""
$DB = ""
$StorageKey = Get-AutomationVariable -Name ""
$User = ""
$Pass = Get-AutomationVariable -Name ""
$Password = ConvertTo-SecureString $Pass -AsPlainText -Force 
$BackupPath = $DB + (Get-Date).ToString("yyyy-MM-dd")
$StorageUri = "https://######.blob.core.windows.net/deploymentbackups/$BackupPath.bacpac"

$backupjob = New-AzSqlDatabaseExport -ResourceGroupName $RG -ServerName $Server -DatabaseName $DB -StorageKeyType "StorageAccessKey" -StorageKey $StorageKey -StorageUri $StorageUri -AuthenticationType "AdPassword" -AdministratorLogin $User -AdministratorLoginPassword $Password
Write-Output $backupjob
$jobstatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $backupjob.OperationStatusLink
Write-Output "Start of database backup"
while ($jobstatus.Status -eq "InProgress"){
   $jobstatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $backupjob.OperationStatusLink
   $jobstatus.Status
   Start-Sleep -s 15
   }
Write-Output "Database backup completed"


}
catch
{
    $message = $_.Exception.Message
    Write-Output $message
    throw $message
}
