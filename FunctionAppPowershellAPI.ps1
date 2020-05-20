# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' porperty is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"



$timeutc = (Get-Date -UFormat %R)
Write-Host "24-hour format time is: $timeutc"

$starttimeutc = "10:00"
$endtimeutc = "12:00"

if ($timeutc -ge $starttimeutc -and $timeutc -le $endtimeutc){
    Write-Host "Sending API Call for sync..."

    $resourceID = $Env:ResourceId
    $clientID = $Env:ClientId
    $username = $Env:ClientUsername
    $clientSecret = $Env:ClientSecret
    $password = $Env:SystemPass
    $url = $Env:Url 
    $authBody = @{
     'resource'=$resourceID
     'client_id'=$clientID
     'client_secret'=$clientSecret
     'grant_type'='password'
     'username'=$username
     'password'=$password
     }
    $auth = Invoke-RestMethod -Uri $url -Body $authBody -Method POST -Verbose
    $token = $auth.access_token

    $endpointUrl = $Env:EndpointUrl

    $headerParams = @{
     'Authorization'="Bearer $token"
     'Content-Type'='application/json'
     }
     $results = Invoke-WebRequest -Uri $endpointUrl -Body "" -Headers $headerParams -Method POST -Verbose
     $statuscoderesult = $results.StatusCode
    Write-Host "Status Code for API Call is $statuscoderesult"
}
else{
    Write-Host "Timeslot for sending API Call for sync is not present, skipping..."
}

