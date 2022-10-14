#!/usr/bin/env pwsh

##########################

if($IsLinux){
    function wsl() {
        $params = $args[4..($args.Count-1)]
        sudo @params
    }
}

. "$PSScriptRoot/_utils.ps1"

$on = [System.Char]::ConvertFromUtf32([System.Convert]::toInt32("1F4A1",16))

Write-Host "$on To distribute the key will rely on wsl, and use sshpass"
wsl -u root -d Ubuntu apt install sshpass

if(!(Test-Path $tmp/private_key)){
  Write-Host "$on Creating key pair using windows ssh-keygen"
  ssh-keygen -t rsa -P `"`" -f $tmp/private_key
}

Write-Host "$on Sending the key to servers"
$pass     = if(${env:PASS}){${env:PASS}}else{Read-Host "Server password"}
$key_pub  = Get-Content -Raw  $tmp/private_key.pub
$key      = (Get-Content -Raw  $tmp/private_key).replace("`n","\n")

# TODO: Maybe do this process through one of the external servers instead (to not deal with wsl)
$setup_ssh_key = @"
echo \`$HOSTNAME 'with $key_pub';
mkdir -p \`$HOME/.ssh;
echo '$key_pub' > \`$HOME/.ssh/authorized_keys;
chmod 700 \`$HOME/.ssh;
chmod 600 \`$HOME/.ssh/authorized_keys;
touch \`$HOME/.hushlogin;
echo -e '$key' > \`$HOME/.ssh/id_rsa;
chmod 600 \`$HOME/.ssh/id_rsa;
"@

##############################################
# If there is a opnsense router setup and no gateway are needed
if($env:ROUTING -eq "opnsense"){

runp $($zone.az9.gw) $pass $(if($IsLinux){$setup_ssh_key.replace("\$","$")}else{$setup_ssh_key}) # Only escape if using wsl
  
# Distribute the key to hosts in the lab
Write-Host "$on Using $($zone.az9.gw) as the bastion"
runex $($zone.az9.gw) @"
cat > ~/cmd <<EOF
$setup_ssh_key
EOF
echo Running commands from `$HOSTNAME;
sshpass -p "$pass" ssh -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no test@10.211.0.10 `$(cat ~/cmd)
sshpass -p "$pass" ssh -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no test@10.211.0.20 `$(cat ~/cmd)
sshpass -p "$pass" ssh -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no test@10.212.0.10 `$(cat ~/cmd)
sshpass -p "$pass" ssh -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no test@10.212.0.20 `$(cat ~/cmd)
sshpass -p "$pass" ssh -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no test@10.212.0.30 `$(cat ~/cmd)
sshpass -p "$pass" ssh -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no test@10.219.0.10 `$(cat ~/cmd)
sshpass -p "$pass" ssh -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no test@10.219.0.20 `$(cat ~/cmd)
sshpass -p "$pass" ssh -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no test@10.219.0.30 `$(cat ~/cmd)
sshpass -p "$pass" ssh -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no test@10.219.0.40 `$(cat ~/cmd)
rm ~/cmd
"@

push 9 40 $PSScriptRoot/../scripts/ip-ubuntu.sh /home/test/ip-ubuntu.sh
push 9 40 $PSScriptRoot/../scripts/role-docker.sh /home/test/role-docker.sh
runex $($zone.az9.gw) @"
scp -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ~/*.sh test@10.211.0.10:~
scp -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ~/*.sh test@10.211.0.20:~
scp -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ~/*.sh test@10.212.0.10:~
scp -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ~/*.sh test@10.212.0.20:~
scp -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ~/*.sh test@10.212.0.30:~
scp -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ~/*.sh test@10.219.0.10:~
scp -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ~/*.sh test@10.219.0.20:~
scp -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ~/*.sh test@10.219.0.30:~
scp -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ~/*.sh test@10.219.0.40:~
"@

##############################################
# If using servers as individual routers for each network
} else {

# NAT: https://blogs.fsfe.org/viktor/archives/79
$setup = @"
echo -e '\U0001F4A1' `$HOSTNAME: installing package...
sudo apt install -y sshpass

echo -e '\U0001F4A1' `$HOSTNAME: setting routes...
sudo bash -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'
sudo iptables -t nat -A POSTROUTING -o ens224 -j MASQUERADE
"@

$zone

runp $($zone.az1.gw) $pass $setup_ssh_key
runp $($zone.az2.gw) $pass $setup_ssh_key
runp $($zone.az9.gw) $pass $setup_ssh_key

Write-Host "$on Setting up gateway routes"
runex $($zone.az1.gw) @"
$setup
sudo ip route add $($zone.az2.subnet) via $($zone.az2.gw)
sudo ip route add $($zone.az9.subnet) via $($zone.az9.gw)
ip route
"@

runex $($zone.az2.gw) @"
$setup
sudo ip route add $($zone.az1.subnet) via $($zone.az1.gw)
sudo ip route add $($zone.az9.subnet) via $($zone.az9.gw)
ip route
"@

runex $($zone.az9.gw) @"
$setup
sudo ip route add $($zone.az1.subnet) via $($zone.az1.gw)
sudo ip route add $($zone.az2.subnet) via $($zone.az2.gw)
ip route
"@

Write-Host "$on Accessing hosts via each subnet's gateway"
# Distribute the key to hosts in the lab
runex $($zone.az9.gw) @"
cat > ~/cmd <<EOF
$setup_ssh_key
EOF
sshpass -p "$pass" ssh -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no test@10.211.0.10 `$(cat ~/cmd)
sshpass -p "$pass" ssh -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no test@10.211.0.20 `$(cat ~/cmd)
sshpass -p "$pass" ssh -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no test@10.212.0.10 `$(cat ~/cmd)
sshpass -p "$pass" ssh -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no test@10.212.0.20 `$(cat ~/cmd)
sshpass -p "$pass" ssh -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no test@10.212.0.30 `$(cat ~/cmd)
sshpass -p "$pass" ssh -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no test@10.219.0.10 `$(cat ~/cmd)
sshpass -p "$pass" ssh -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no test@10.219.0.20 `$(cat ~/cmd)
sshpass -p "$pass" ssh -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no test@10.219.0.30 `$(cat ~/cmd)
sshpass -p "$pass" ssh -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no test@10.219.0.40 `$(cat ~/cmd)
rm ~/cmd
"@

# Push all scripts to update hosts as needed
push 9 1 $PSScriptRoot/../scripts/ip-ubuntu.sh /home/test/ip-ubuntu.sh
push 9 1 $PSScriptRoot/../scripts/role-docker.sh /home/test/role-docker.sh
runex $($zone.az9.gw) @"
scp -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ~/*.sh test@10.211.0.10:~
scp -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ~/*.sh test@10.211.0.20:~
scp -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ~/*.sh test@10.212.0.10:~
scp -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ~/*.sh test@10.212.0.20:~
scp -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ~/*.sh test@10.212.0.30:~
scp -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ~/*.sh test@10.219.0.10:~
scp -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ~/*.sh test@10.219.0.20:~
scp -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ~/*.sh test@10.219.0.30:~
scp -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ~/*.sh test@10.219.0.40:~
"@

}