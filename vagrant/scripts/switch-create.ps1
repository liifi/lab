# Altered from: https://superuser.com/questions/1354658/hyperv-static-ip-with-vagrant
# See: https://www.petri.com/using-nat-virtual-switch-hyper-v

$id=$args[0]
$subnet="10.11$id.0"
$switchName="az$id"
$natName="${switchName}NAT"

If (${switchName} -in (Get-VMSwitch | Select-Object -ExpandProperty Name) -eq $FALSE) {
    "Creating Internal-only switch named ${switchName} on Windows Hyper-V host..."
    New-VMSwitch -SwitchName ${switchName} -SwitchType Internal
    New-NetIPAddress -IPAddress "${subnet}.1" -PrefixLength 24 -InterfaceAlias "vEthernet (${switchName})"
    New-NetNAT -Name "${natName}" -InternalIPInterfaceAddressPrefix "${subnet}.0/16"
}
else {
    "${switchName} for static IP configuration already exists; skipping"
}

If ("${subnet}.1" -in (Get-NetIPAddress | Select-Object -ExpandProperty IPAddress) -eq $FALSE) {
    "Registering new IP address ${subnet}.1 on Windows Hyper-V host..."

    New-NetIPAddress -IPAddress "${subnet}.1" -PrefixLength 24 -InterfaceAlias "vEthernet (${switchName})"
}
else {
    "${subnet}.1 for static IP configuration already registered; skipping"
}

If ("${subnet}.0/16" -in (Get-NetNAT | Select-Object -ExpandProperty InternalIPInterfaceAddressPrefix) -eq $FALSE) {
    "Registering new NAT adapter for ${subnet}.0/16 on Windows Hyper-V host..."

    New-NetNAT -Name "${natName}" -InternalIPInterfaceAddressPrefix "${subnet}.0/16"
}
else {
    "${subnet}.0/16 for static IP configuration already registered; skipping"
}
