$automationaccname = ""
$runbookname = ""
$rg = ""

$job = Start-AzAutomationRunbook -AutomationAccountName $automationaccname -Name $runbookname -ResourceGroupName $rg

$jobid = $job.JobId

$jobstatusfull = Get-AzAutomationJob -Id $jobid -ResourceGroupName $rg -AutomationAccountName $automationaccname

$jobstatus = $jobstatusfull.Status

while($jobstatus -like "Running" -or $jobstatus -like "New")
{
    Write-Host "Backup is running"
    $jobstatusfull = Get-AzAutomationJob -Id $jobid -ResourceGroupName $rg -AutomationAccountName $automationaccname

    $jobstatus = $jobstatusfull.Status

    Start-Sleep 15
}

Write-Host "Backup is $jobstatus"
