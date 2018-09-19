# Check the status of all Dell RAID arrays via omreport and report accordingly.
#
# Note: omreport is part of Dell OpenManage.
#
# An OK array looks like this:
#     State                   : Ready
#
# A failed one looks like this:
#     State                   : Degraded
#     State                   : Rebuilding

# Verify Powershell 5 or higher. Report Critical back to Nagios otherwise.
If ($PSVersionTable.PSVersion.Major -lt 5) {
    "Powershell version 5 or higher required."
    Exit 2
}

$ok_count = 0
$degraded_count = 0

Try {
    $om_cmd = "omreport storage vdisk"
    $om_output = Invoke-Expression $om_cmd
    $om_lines = $om_output.Split("`r`n")
} Catch {
    "Could not execute omreport. Is OpenManage installed?"
    Exit 2
}

$status_regex = "^\s*State\s+:\s+"
Foreach ($om_line in $om_lines) {
    If ($om_line -match $status_regex) {
        If ($om_line -match "Ready") {
            $ok_count++
        } Else {
            $degraded_count++
        }
    }
}

If ($degraded_count -gt 0) {
    $msg = "CRITICAL: Dell RAID is degraded. Check command: $($om_cmd)"
    $code = 2
} ElseIf ($ok_count -gt 0) {
    $msg = "OK: Dell RAID is OK."
    $code = 0
} Else {
    $msg = "CRITICAL: No RAID found. Check command: $($om_cmd)"
    $code = 2
}

$msg
Exit $code
