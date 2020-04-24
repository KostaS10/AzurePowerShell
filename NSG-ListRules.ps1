Import-Module Az.Accounts
Import-Module Az.Automation
Import-Module Az.Storage
Import-Module Az.KeyVault
Import-Module Az.Network
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
$rg = ""

#Set storage account context and previous month value
$sastoken = (Get-AzKeyVaultSecret -VaultName $vaultname -Name $secretname).SecretValueText
$context = New-AzStorageContext -StorageAccountName $stgaccname -SasToken $sastoken

$lastMonth = (Get-Date).AddMonths(-1)
$lastMonthNumber = $lastMonth.Month
$lastMonthYear = $lastMonth.Year

#List all NSGs in RG and go through them
$nsglist = (Get-AzNetworkSecurityGroup -ResourceGroupName $rg).Name
foreach($nsgitem in $nsglist){
    $nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $rg -Name $nsgitem

        #NSG rules
    $nsgrulestable=@()
 
    $nsgrules = $nsg.SecurityRules
    foreach($nsgrule in $nsgrules){
        $Priority = $nsgrule.Priority
        $Name = $nsgrule.Name
        $Description = $nsgrule.Description -replace "`n",", "
        $Protocol = $nsgrule.Protocol
        $SourcePortRange = $nsgrule.SourcePortRange
        $SourceAddressPrefix = $nsgrule.SourceAddressPrefix
        $DestinationPortRange = $nsgrule.DestinationPortRange
        $DestinationAddressPrefix = $nsgrule.DestinationAddressPrefix
        $Access = $nsgrule.Access
        $Direction = $nsgrule.Direction

        $nsgrulestable += new-object psobject -property @{Priority="$Priority";
                                                        Name="$Name";
                                                        Description="$Description";
                                                        Protocol="$Protocol";
                                                        SourcePortRange="$SourcePortRange";
                                                        SourceAddressPrefix="$SourceAddressPrefix";
                                                        DestinationPortRange="$DestinationPortRange";
                                                        DestinationAddressPrefix="$DestinationAddressPrefix";
                                                        Access="$Access";
                                                        Direction="$Direction";
                                                    }

    
    }

    #Default NSG rules

    $defaultruleslist = @()
    $defaultnsgrules = $nsg.DefaultSecurityRules
    foreach($defaultnsgrule in $defaultnsgrules){
        $Priority = $defaultnsgrule.Priority
        $Name = $defaultnsgrule.Name
        $Description = $nsgrule.Description -replace "`n",", "
        $Protocol = $defaultnsgrule.Protocol
        $SourcePortRange = $defaultnsgrule.SourcePortRange
        $SourceAddressPrefix = $defaultnsgrule.SourceAddressPrefix
        $DestinationPortRange = $defaultnsgrule.DestinationPortRange
        $DestinationAddressPrefix = $defaultnsgrule.DestinationAddressPrefix
        $Access = $defaultnsgrule.Access
        $Direction = $defaultnsgrule.Direction

        $defaultruleslist += new-object psobject -property @{Priority="$Priority";
                                                            Name="$Name";
                                                            Description="$Description";
                                                            Protocol="$Protocol";
                                                            SourcePortRange="$SourcePortRange";
                                                            SourceAddressPrefix="$SourceAddressPrefix";
                                                            DestinationPortRange="$DestinationPortRange";
                                                            DestinationAddressPrefix="$DestinationAddressPrefix";
                                                            Access="$Access";
                                                            Direction="$Direction";
                                                            }                                                       

}

#Combining default and other NSG rules into one list and exporting list
    $nsgrulestable += $defaultruleslist

    $path =  "$env:TEMP\$nsgitem" + "_" + $lastMonthNumber + "_" + $lastMonthYear + ".csv"
    $nsgrulestablesorted = $nsgrulestable | Sort-Object {[int]$_.Priority} 

    $nsgrulestablesorted | select Priority, Name, Description, Protocol, SourcePortRange, SourceAddressPrefix, DestinationPortRange, DestinationAddressPrefix, Access, Direction |
                            Export-Csv $path -NoTypeInformation
    $blobpath = "$lastMonthYear" + "-" + "$lastMonthNumber" + "/" + "$nsgitem" + ".csv"
    
    Set-AzStorageBlobContent -Context $context -Container "nsg-ruleslist" -File $path -Blob $blobpath -Force

}

}
catch
{
    $message = $_.Exception.Message
    Write-Output $message
    throw $message
}
