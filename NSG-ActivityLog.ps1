Import-Module Az.Accounts
Import-Module Az.Automation
Import-Module Az.Storage
Import-Module Az.KeyVault
Import-Module Az.OperationalInsights
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

#Defining dates
$lastMonth = (Get-Date).AddMonths(-1)
$lastMonthNumber = $lastMonth.Month
$lastDay = [DateTime]::DaysInMonth($lastMonth.Year, $lastMonth.Month)
$firstDay = "1"
$lastMonthYear = $lastMonth.Year


$startdate = [string]$lastMonthNumber + "/" + $firstDay + "/" + $lastMonthYear
$enddate = [string]$lastMonthNumber + "/" + $lastDay + "/" + $lastMonthYear

#Defining query and commands
$query = "AzureActivity
| where OperationNameValue startswith ""Microsoft.Network/networkSecurityGroups/securityRules"" 
and OperationName != ""'audit' Policy action."" 
and ActivityStatus == ""Succeeded""   
and TimeGenerated >= datetime($startdate)
and TimeGenerated <= datetime($enddate)
| sort by TimeGenerated desc"

$workspaceId = (Get-AzOperationalInsightsWorkspace -Name $workspaceName -ResourceGroupName $rgName).CustomerId.Guid


#Executing LogAnalytics query and parsing results
$result = Invoke-AzOperationalInsightsQuery -WorkspaceId $workspaceId -Query $query
$resultsArray = [System.Linq.Enumerable]::ToArray($result.Results) 

$path =  "$env:TEMP\NSG_ActivityLog" + "_" + $lastMonthNumber + "_" + $lastMonthYear + ".csv"
$resultsArray | Export-Csv $path

#Set storage context and date

$sastoken = Get-AutomationVariable -Name "PRDSASToken"
$context = New-AzStorageContext -StorageAccountName $stgaccname -SasToken $sastoken

$files = Get-ChildItem "$env:TEMP\"
foreach($file in $files){
    $filename = $file.Name
    Set-AzStorageBlobContent -Context $context -Container "nsg-activitylogs" -File "$env:TEMP\$filename" -Blob $filename -Force
}


}
catch
{
    $message = $_.Exception.Message
    Write-Output $message
    throw $message
}
