## WebResponseCheck - Fraser Smith 2023
## A powershell script that can read and output from a log file with the following fields:
## datestamp, request GUID, action type, requested url, -, status, -, server/worker id
## Default response time is 500ms, this can be edited on line 50 and line 80.

# Below can be changed by commenting out and using the following instead to hardcode the location
# $logFilePath = "path/to/log/file"
# $logEntries = Get-Content $logFilePath
$logEntries = Get-Content $(Read-host -Prompt "Please enter the path to the log file you want to read")

# Section for defining the entry types in the log file
$entriesByRequestGuid = @{}
foreach ($entry in $logEntries) {
    $fields = $entry -split '\s+'
    $requestGuid = $fields[1]

    if (-not $entriesByRequestGuid.ContainsKey($requestGuid)) {
        $entriesByRequestGuid[$requestGuid] = @{}
    }

    $entriesByRequestGuid[$requestGuid][$fields[2]] = @{
        'DateStamp' = $fields[0]
        'ServerId' = $fields[7]
        'Url' = $fields[3]
    }
}

# Creating the hash tables (more efficient than using arrays)
$servers = @{}
$serverResponseTimes = @{}
$outputs = @()

# Searching the log file for the different GUIDs and the action type that is being used
foreach ($requestGuid in $entriesByRequestGuid.Keys) {
    $postEntry = $entriesByRequestGuid[$requestGuid]['POST']
    if (-not $postEntry) {
        continue
    }

    $handleEntry = $entriesByRequestGuid[$requestGuid]['HANDLE']
    $respondEntry = $entriesByRequestGuid[$requestGuid]['RESPOND']
    # Finding the frontend server ID with regex "\d" means digit
    $frontEndServer = $postEntry['ServerId'] -replace 'frontend(\d+)', 'frontend$1'
    # Finding the worker server ID and pulling the response time difference
    if ($handleEntry) {
        $workerServer = $handleEntry['ServerId'] -replace 'worker(\d+)', 'worker$1'
        $responseTimeDifference = [datetime]::Parse($handleEntry['DateStamp']) - [datetime]::Parse($postEntry['DateStamp'])
        $responseTimeDifference = $responseTimeDifference.TotalMilliseconds
        # Comparing the response time difference and seeing if it matches 500ms or more (this is a configurable line)
        if ($responseTimeDifference -ge 500) {
            $servers[$frontEndServer] += 1
            $servers[$workerServer] += 1
            # adding if it is frontend server or worker server
            if (-not $serverResponseTimes.ContainsKey($frontEndServer)) {
                $serverResponseTimes[$frontEndServer] = @()
            }
            if (-not $serverResponseTimes.ContainsKey($workerServer)) {
                $serverResponseTimes[$workerServer] = @()
            }
            $serverResponseTimes[$frontEndServer] += $responseTimeDifference
            $serverResponseTimes[$workerServer] += $responseTimeDifference
            # This is the POST to HANDLE output for the output file that is created
            $output = @"
Request GUID: $requestGuid
Action: POST to HANDLE
URL: $($handleEntry['Url'])
Front-end Server: $frontEndServer
Worker Server: $workerServer
Response Time Difference: $responseTimeDifference ms

"@
            $outputs += $output
        }
    }

    if ($respondEntry) {
        $responseTimeDifference = [datetime]::Parse($respondEntry['DateStamp']) - [datetime]::Parse($handleEntry['DateStamp'])
        $responseTimeDifference = $responseTimeDifference.TotalMilliseconds
        # Comparing the response time difference and seeing if it matches 500ms or more (this is a configurable line)
        if ($responseTimeDifference -ge 500) {
            $servers[$frontEndServer] += 1
            # adding if it is frontend server or worker server
            if (-not $serverResponseTimes.ContainsKey($frontEndServer)) {
                $serverResponseTimes[$frontEndServer] = @()
            }
            $serverResponseTimes[$frontEndServer] += $responseTimeDifference
            # This is the HANDLE to RESPOND output for the output file that is created
            $output = @"
Request GUID: $requestGuid
Action: HANDLE to RESPOND
URL: $($postEntry['Url'])
Front-end Server: $frontEndServer
Worker Server: $workerServer
Response Time Difference: $responseTimeDifference ms

"@
            $outputs += $output
        }
    }
}
# Calculating average response time for console and output file just for extra info
$serverStats = "Server Statistics:`n"
foreach ($server in $servers.Keys | Sort-Object -Property @{Expression={[int]$servers[$_]} ; Descending=$true}) {
    $entryCount = $servers[$server]
    $responseTimes = $serverResponseTimes[$server]
    $averageResponseTime = [Math]::Round(($responseTimes | Measure-Object -Average).Average, 2)

    $serverStats += "Server: $server | Entry Count: $entryCount | Average Response Time: $averageResponseTime ms`n"
}

# Asking where to save output file and generating it
# $serverStatsPath = "path/to/log/output/file"
$serverStatsPath = $(Read-host -Prompt "Please enter the path to where the output file should be saved (including file name and extension)")
$outputs += $serverStats
$outputs | Out-File -FilePath $serverStatsPath

# Displaying info in console window to show a brief overview
$warningMessage = "Output file has been saved in", $serverStatsPath, "`nThe following servers have a response time of over 500ms. They should be investigated:`n`n"
$warningMessage += $serverStats

Write-Host $warningMessage
