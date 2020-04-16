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
and ResourceGroup == "$resourceGroup"
and OperationName != ""'audit' Policy action.""
and TimeGenerated >= datetime($startdate)
and TimeGenerated <= datetime($enddate)
| sort by TimeGenerated desc"

$workspaceId = (Get-AzOperationalInsightsWorkspace -Name "$workspacename" -ResourceGroupName "resourceGroup").CustomerId.Guid


#Executing LogAnalytics query and parsing results
$results = Invoke-AzOperationalInsightsQuery -WorkspaceId $workspaceId -Query $query
$resultsArray = [System.Linq.Enumerable]::ToArray($results.Results)

$resulting=@()
$item1=@()

foreach($resultsArrayItem in $resultsArray){
    $item1 = $resultsArrayItem.Properties

    if($item1 -notlike "*responseBody*"){
    
        $provisioningState = ""
        $description = ""
        $protocol = ""
        $sourcePortRange = ""
        $sourceAddressPrefix = ""
        $access = ""
        $priority = ""
        $direction = ""
        $sourcePortRanges = ""
        $destinationPortRanges = ""
        $sourceAddressPrefixes = ""
        $destinationAddressPrefixes = ""
    }
    else{
        

        $item2 = $item1 | ConvertFrom-Json
        $item3 = $item2.responseBody | ConvertFrom-Json
        $provisioningState = [string]$item3.properties.provisioningState
        $description = [string]$item3.properties.description
        $protocol = [string]$item3.properties.protocol
        $sourcePortRange = [string]$item3.properties.sourcePortRange
        $sourceAddressPrefix = [string]$item3.properties.sourceAddressPrefix
        $access = [string]$item3.properties.access
        $priority = [string]$item3.properties.priority
        $direction = [string]$item3.properties.direction
        $sourcePortRanges = [string]$item3.properties.sourcePortRanges
        $destinationPortRanges = [string]$item3.properties.destinationPortRanges
        $sourceAddressPrefixes = [string]$item3.properties.sourceAddressPrefixes
        $destinationAddressPrefixes = [string]$item3.properties.destinationAddressPrefixes
    }
    $resulting += $resultsArrayItem | select TimeGenerated, CallerIpAddress, OperationNameValue, Caller, EventSubmissionTimestamp, OperationName, Resource, 
    @{n='Description';e={$description}}, @{n='ProvisioningState';e={$provisioningState}}, @{n='Protocol';e={$protocol}}, @{n='SourcePortRange';e={$sourcePortRange}},
    @{n='SourceAddressPrefix';e={$sourceAddressPrefix}}, @{n='Access';e={$access}}, @{n='Priority';e={$priority}}, @{n='Direction';e={$direction}},
    @{n='SourcePortRanges';e={$sourcePortRanges}}, @{n='DestinationPortRanges';e={$destinationPortRanges}}, @{n='SourceAddressPrefixes';e={$sourceAddressPrefixes}},
    @{n='DestinationAddressPrefixes';e={$destinationAddressPrefixes}}
}



$path =  "$env:TEMP\NSG_ActivityLog" + "_" + $lastMonthNumber + "_" + $lastMonthYear + ".csv"
$resulting | Export-Csv -Path $path

#Set storage context and date

$sastoken = Get-AutomationVariable -Name $prdsastoken
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
