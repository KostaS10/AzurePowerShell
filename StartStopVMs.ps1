Param
(
    [Parameter(Mandatory=$false)]
    [String] $startstop
)

Import-Module Az.Accounts
Import-Module Az.Automation
Import-Module Az.Compute

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

Write-Output "Starting task"
if($startstop -eq "start"){
    Write-Output "StartVM task initiated"
    $vms = Get-AzVM -Status
    foreach($vm in $vms){
        $vmname = $vm.Name
        $vmrg = $vm.ResourceGroupName
        Write-Output "Starting $vmname"
        Start-AzVM -ResourceGroupName $vmrg -Name $vmname
        while($vmstate -ne "VM running"){
            $vmstate = (Get-AzVM -Status -ResourceGroupName $vmrg -Name $vmname).Statuses.DisplayStatus[1]
            Start-Sleep -s 5
        }
        Write-Output "Started $vmname"
    }

}
if($startstop -eq "stop"){
    Write-Output "StopVM task initiated"
    $vms = Get-AzVM -Status | where {$_.Name -like "*DOPS*"}
    foreach($vm in $vms){
        $vmname = $vm.Name
        $vmrg = $vm.ResourceGroupName
        Write-Output "Stopping $vmname"
        Stop-AzVM -ResourceGroupName $vmrg -Name $vmname -Force
        while($vmstate -ne "VM deallocated"){
            $vmstate = (Get-AzVM -Status -ResourceGroupName $vmrg -Name $vmname).Statuses.DisplayStatus[1]
            Start-Sleep -s 5
        }
        Write-Output "Stopped $vmname"
    }
}

