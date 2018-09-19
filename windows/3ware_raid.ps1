# Check the status of all 3ware RAID arrays via tw_cli and report accordingly.
#
# Note: tw_cli is part of the official 3ware driver package.
#
# An OK array looks like this:
#  u0    RAID-1    OK             -       -       -       465.651   Ri     OFF
#
# A failed one looks like this:
#  u0    RAID-5    DEGRADED       -       -       -       1852.63   Ri     OFF


# Verify Powershell 5 or higher. Report Critical back to Nagios otherwise.
If ($PSVersionTable.PSVersion.Major -lt 5) {
    "Powershell version 5 or higher required."
    Exit 2
}

# Verify tw_cli installed and functional.
Try {
    $info_cmd = "tw_cli info"
    $info_output = Invoke-Expression $info_cmd
    $info_lines = $info_output.Split("`r`n")
} Catch {
    "CRITICAL: Could not execute tw_cli. Are the 3ware drivers installed?"
    Exit 2
}

# Find controllers with tw_cli. Eg: u0, u1, and u2
$controllers = @()
$controller_regex = "^(c\d+)\s+"
Foreach ($info_line in $info_lines) {
    $regex_match = [regex]::match($info_line, $controller_regex)
    If ($regex_match.Success) {
        $controllers += $regex_match.Groups[1].Value
    }
}

If (-Not $controllers) {
    "CRITICAL: Could not find any controllers in 'tw_cli info'"
    Exit 2
}

# Run "tw_cli info cX" against each controller and combine the output.
$unit_lines = @()
Foreach ($controller in $controllers) {
    $unit_cmd = "tw_cli info $controller"
    $unit_output = Invoke-Expression $unit_cmd
    $unit_lines = $unit_output.Split("`r`n")
}

# Parse $unit_lines, looking for controller statuses.
$ok_messages = @()
$failed_messages = @()
$unit_regex = "^(u\d+)\s+\S+\s+(\S+)"
Foreach ($unit_line in $unit_lines) {
    $regex_match = [regex]::match($unit_line, $unit_regex)
    If ($regex_match.Success) {
        $unit = $regex_match.Groups[1].Value
        $unit_status = $regex_match.Groups[2].Value
        If ($unit_status -eq "OK") {
            $ok_messages += "$unit is $unit_status"
        } Else {
            $failed_messages += "$unit is $unit_status"
        }
    }
}

# Exit based on $ok_messages and $failed_messages.
If ($failed_messages.Length -gt 0) {
    $failed_messages_combined = [string]::Join(", ", $failed_messages)
    $msg = "CRITICAL: $failed_messages_combined"
    $code = 2
} ElseIf ($ok_messages.Length -gt 0) {
    $msg = "OK: 3ware RAID is OK"
    $code = 0
} Else {
    $msg = "CRITICAL: No RAID arrays found. Check command: $info_cmd"
    $code = 2
}

$msg
Exit $code
