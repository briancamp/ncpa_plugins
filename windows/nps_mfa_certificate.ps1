 #
# Check the expiration of the Microsoft NPS Extension certificate and begin reporting critical at 60 days.
#


If ($PSVersionTable.PSVersion.Major -lt 5) {
    "Powershell version 5 or higher required"
    Exit 2
}

# Gather all NPS certificates in LocalMachine, by checking the Subject Name
$nps_certificates = Get-ChildItem Cert:\LocalMachine\ -Recurse | Where-Object -FilterScript {
    $_.Subject -match "Microsoft NPS Extension"
}
If (-Not $nps_certificates) {
    "Could not find any Microsoft NPS Extension certificates installed"
    Exit 2
}


$latest_certificate = ($nps_certificates | Sort-Object -Property NotAfter -Descending)[0]
$expiration = $latest_certificate.NotAfter
$now = Get-Date
$days_to_expiration = ($expiration - $now).Days

If ($days_to_expiration -lt 0) {
    $exit_msg = "NPS MFA certificate is expired."
    $exit_code = 2
} ElseIf ($days_to_expiration -lt 60) {
    $exit_msg = "NPS MFA certificate expires $expiration"
    $exit_code = 2
} Else {
    $exit_msg = "NPS MFA certificate expires $expiration"
    $exit_code = 0
}

$exit_msg
Exit $exit_code 
