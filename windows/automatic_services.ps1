# Check to see if any Automatic services are Stopped and report accordingly.
#
# Command line options serve as an ignore list.
# For example to check while ignoring Chrome's update service:
#     automatic_services.ps1 "Google Update Service"
#

Function Test-Regexes {
    Param(
        $test_str,
        $regexes
    )
    
    Foreach ($regex in $regexes){
        If ($test_str -match $regex) {
            Return $True
        }
    }
    Return $False
}

# Verify Powershell 5 or higher. Report Critical back to Nagios otherwise.
If ($PSVersionTable.PSVersion.Major -lt 5) {
    "Powershell version 5 or higher required."
    Exit 2
}       

# Each command line argument is a regex for services to ignore
$ignore_regexes = $args

# All services set to Automatic that aren't currently running
$dead_service_objs =  Get-Service | Where-Object {
    ($_.StartType -match "Automatic") -and ($_.Status -ne "Running")
}

# Names of Automatic services that aren't running
$dead_services = $dead_service_objs | Select-Object -ExpandProperty DisplayName

# Filter out any matching Regexes
$alertable_services = $dead_services | Where-Object -FilterScript {
    (Test-Regexes $_ $ignore_regexes) -ne $True
}

# Exit OK if there are no dead services, else exit Critical and report
If ($alertable_services.Count -eq 0) {
    $code = 0
    $msg = "OK: All automatic services running."
} Else {
    $code = 2
    $msg = "CRITICAL: Not running: " + [string]::Join(", ", $alertable_services)
}

$msg
Exit $code
