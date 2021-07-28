$runningVMList = @()

$managementGroup = ""
$mg = Get-AzManagementGroup -GroupName $managementGroup -Expand -Recurse
$mgName = $mg.Name

$subscriptions = $mg.Children

try{
    if($subscriptions){
        foreach($subscription in $subscriptions){
            Set-AzContext -SubscriptionName $subscription.DisplayName
            $subName = $subscription.DisplayName

            Write-Host "Listing VMs in subscription $subName"

            $vms = Get-AzVM -Status

            if($vms){
                foreach($vm in $vms){
                    $vmName = $vm.Name
                    if($vm.PowerState -eq "VM running"){
                        Write-Host "VM $vmName is already running, no action necessary."
                        $runningVMList += $vmName

                    }
                    elseif(($vm.PowerState -eq "VM stopped") -or ($vm.PowerState -eq "VM deallocated")){
                        Write-Host "VM $vmName stopped/deallocated, starting"
                        Start-AzVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName

                        do{
                            Start-Sleep -s 5
                            Write-Host "Waiting for $vmName to have running status"
                            $vmstatus = Get-AzVM -Name $vm.Name -Status
                        }until($vmstatus.PowerState -eq "VM running")

                        Write-Host "VM $vmName started successfully"
                        Write-Host "Shutting down $vmName"
                        Stop-AzVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Force -NoWait

                    }

                }

            } else {
                Write-Host "No VMs found in $subName"
            }  


        }

        Write-Host "VMs that were already running and were not part of the reboot:"
        Write-Host $runningVMList


    }else {
        Write-Host "No subscriptions found under $mgName"
    }




} catch {
    Write-Host "$_.Exception"
}
