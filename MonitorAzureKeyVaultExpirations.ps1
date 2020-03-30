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

#Set date and Logic App URL

$date = (Get-Date).ToString("yyyy-MM-dd")

$logicappurl = Get-AutomationVariable "LogicAppURL"

Write-Output $date

#Check KeyVault Keys expiration
$keys = Get-AzKeyVaultKey -VaultName $keyvaults
foreach($key in $keys){
    if($key.Expires){
    $keyname = $key.Name
    $expires = $key.Expires 

    $expirydate = ($expires).ToString("yyyy-MM-dd")

    $twoweeksbeforeexpiry = ($expires).AddDays(-14).ToString("yyyy-MM-dd")
    $oneweekbeforeexpiry = ($expires).AddDays(-7).ToString("yyyy-MM-dd")
    $onedaybeforeexpiry = ($expires).AddDays(-1).ToString("yyyy-MM-dd")

    if($date -eq $twoweeksbeforeexpiry){
        $subject = "$keyname Key in KeyVault $keyvaults expires in two weeks"
        Write-Output $subject

        $Body = [PSCustomObject]@{
        To      = "<email>"
        Subject = "$subject"
        Body    = "This is an automated notification from Azure: $subject . Please look into renewing."
        }

        # Create a line that creates a JSON from this object
        $JSONBody = $Body | ConvertTo-Json

        Invoke-RestMethod -Method POST -Uri $logicappurl -Body $JSONBody -ContentType 'application/json'
    }
    elseif($date -eq $oneweekbeforeexpiry){
        $subject = "$keyname Key in KeyVault $keyvaults expires in one week"
        Write-Output $subject

        $Body = [PSCustomObject]@{
        To      = "<email>"
        Subject = "$subject"
        Body    = "This is an automated notification from Azure: $subject . Please look into renewing."
        }

        # Create a line that creates a JSON from this object
        $JSONBody = $Body | ConvertTo-Json

        Invoke-RestMethod -Method POST -Uri $logicappurl -Body $JSONBody -ContentType 'application/json'
    }
    elseif($date -eq $onedaybeforeexpiry){
        $subject = "$keyname Key in KeyVault $keyvaults expires in one day"
        Write-Output $subject

        $Body = [PSCustomObject]@{
        To      = "<email>"
        Subject = "$subject"
        Body    = "This is an automated notification from Azure: $subject . Please look into renewing."
        }

        # Create a line that creates a JSON from this object
        $JSONBody = $Body | ConvertTo-Json

        Invoke-RestMethod -Method POST -Uri $logicappurl -Body $JSONBody -ContentType 'application/json'
    }
    }
}

#Check KeyVault Secrets expiration

$secrets = Get-AzKeyVaultSecret -VaultName $keyvaults
foreach($secret in $secrets){
    if($secret.Expires){
    $secretname = $secret.Name
    $expires = $secret.Expires 

    $expirydate = ($expires).ToString("yyyy-MM-dd")

    $twoweeksbeforeexpiry = ($expires).AddDays(-14).ToString("yyyy-MM-dd")
    $oneweekbeforeexpiry = ($expires).AddDays(-7).ToString("yyyy-MM-dd")
    $onedaybeforeexpiry = ($expires).AddDays(-1).ToString("yyyy-MM-dd")

    if($date -eq $twoweeksbeforeexpiry){
        $subject = "$secretname Secret in KeyVault $keyvaults expires in two weeks"
        Write-Output $subject

        $Body = [PSCustomObject]@{
        To      = "<email>"
        Subject = "$subject"
        Body    = "This is an automated notification from Azure: $subject . Please look into renewing."
        }

        # Create a line that creates a JSON from this object
        $JSONBody = $Body | ConvertTo-Json

        Invoke-RestMethod -Method POST -Uri $logicappurl -Body $JSONBody -ContentType 'application/json'
    }
    elseif($date -eq $oneweekbeforeexpiry){
        $subject = "$secretname Secret in KeyVault $keyvaults expires in one week"
        Write-Output $subject

        $Body = [PSCustomObject]@{
        To      = "<email>"
        Subject = "$subject"
        Body    = "This is an automated notification from Azure: $subject . Please look into renewing."
        }

        # Create a line that creates a JSON from this object
        $JSONBody = $Body | ConvertTo-Json

        Invoke-RestMethod -Method POST -Uri $logicappurl -Body $JSONBody -ContentType 'application/json'
    }
    elseif($date -eq $onedaybeforeexpiry){
        $subject = "$secretname Secret in KeyVault $keyvaults expires in one day"
        Write-Output $subject

        $Body = [PSCustomObject]@{
        To      = "<email>"
        Subject = "$subject"
        Body    = "This is an automated notification from Azure: $subject . Please look into renewing."
        }

        # Create a line that creates a JSON from this object
        $JSONBody = $Body | ConvertTo-Json

        Invoke-RestMethod -Method POST -Uri $logicappurl -Body $JSONBody -ContentType 'application/json'
    }
    }
}

#Check KeyVault Certificates expiration

$certificates = Get-AzKeyVaultCertificate -VaultName $keyvaults
foreach($certificate in $certificates){
    if($certificate.Expires){
    $certificatename = $certificate.Name
    $expires = $certificate.Expires 

    $expirydate = ($expires).ToString("yyyy-MM-dd")

    $twoweeksbeforeexpiry = ($expires).AddDays(-14).ToString("yyyy-MM-dd")
    $oneweekbeforeexpiry = ($expires).AddDays(-7).ToString("yyyy-MM-dd")
    $onedaybeforeexpiry = ($expires).AddDays(-1).ToString("yyyy-MM-dd")

    if($date -eq $twoweeksbeforeexpiry){
        $subject = "$certificatename Certificate in KeyVault $keyvaults expires in two weeks"
        Write-Output $subject

        $Body = [PSCustomObject]@{
        To      = "<email>"
        Subject = "$subject"
        Body    = "This is an automated notification from Azure: $subject . Please look into renewing."
        }

        # Create a line that creates a JSON from this object
        $JSONBody = $Body | ConvertTo-Json

        Invoke-RestMethod -Method POST -Uri $logicappurl -Body $JSONBody -ContentType 'application/json'
    }
    elseif($date -eq $oneweekbeforeexpiry){
        $subject = "$certificatename Certificate in KeyVault $keyvaults expires in one week"
        Write-Output $subject

        $Body = [PSCustomObject]@{
        To      = "<email>"
        Subject = "$subject"
        Body    = "This is an automated notification from Azure: $subject . Please look into renewing."
        }

        # Create a line that creates a JSON from this object
        $JSONBody = $Body | ConvertTo-Json

        Invoke-RestMethod -Method POST -Uri $logicappurl -Body $JSONBody -ContentType 'application/json'
    }
    elseif($date -eq $onedaybeforeexpiry){
        $subject = "$certificatename Certificate in KeyVault $keyvaults expires in one day"
        Write-Output $subject

        $Body = [PSCustomObject]@{
        To      = "<email>"
        Subject = "$subject"
        Body    = "This is an automated notification from Azure: $subject . Please look into renewing."
        }

        # Create a line that creates a JSON from this object
        $JSONBody = $Body | ConvertTo-Json

        Invoke-RestMethod -Method POST -Uri $logicappurl -Body $JSONBody -ContentType 'application/json'
    }
    }

}
}
catch
{
    $message = $_.Exception.Message
    Write-Output $message
    throw $message
}
