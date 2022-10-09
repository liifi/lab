# Altered from: https://superuser.com/questions/1354658/hyperv-static-ip-with-vagrant
# See: https://www.thomasmaurer.ch/2016/01/change-hyper-v-vm-switch-of-virtual-machines-using-powershell/

$id=$args[0]

"Setting VMs '*az${id}-*' to use NetworkAdapter 'az${id}'"
Get-VM "*az${id}-*" | Get-VMNetworkAdapter | Connect-VMNetworkAdapter -SwitchName "az${id}"
