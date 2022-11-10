$terraform = "$PSScriptRoot/../.terraform"
$tmp = "$terraform/tmp"
New-Item -Force -Path $terraform -Name "tmp" -ItemType "directory" -ErrorAction Ignore | Out-Null
$EXTSUBNET = Get-Content -Raw $PSScriptRoot/config/subnet # The reachable subnet (x.x.x) as opposed to the subnets used by the sandbox

if($env:ROUTING -eq "opnsense"){
  $zone = [PSCustomObject]@{
    az1 = @{ gw="$EXTSUBNET.20"; subnet="10.211.0.0/20" }
    az2 = @{ gw="$EXTSUBNET.20"; subnet="10.212.0.0/20" }
    az9 = @{ gw="$EXTSUBNET.20"; subnet="10.219.0.0/20" }
  }
} else {
  $zone = [PSCustomObject]@{
    az1 = @{ gw="$EXTSUBNET.27"; subnet="10.211.0.0/20" }
    az2 = @{ gw="$EXTSUBNET.28"; subnet="10.212.0.0/20" }
    az9 = @{ gw="$EXTSUBNET.29"; subnet="10.219.0.0/20" }
  }
}

function runp($ip,$pass,$command){ wsl -u root -d Ubuntu sshpass -p "$pass" ssh -o ConnectTimeout=2 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no test@${ip} $command }
function runex($ip,$command){ ssh -t -o ConnectTimeout=2 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $tmp/private_key test@${ip} $command }
function run($az,$id,$command){
  ssh -t -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $tmp/private_key test@$($zone."az$az".gw) `
    "ssh -t -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no test@10.21${az}.0.${id} $(if($command){"<<'EOF'`n$command`nEOF"}else{})"
}
function push($az,$id,$src,$dst){
  $tmppath = "/home/test/uploading"
  scp -o ConnectTimeout=2 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $tmp/private_key $src test@$($zone."az$az".gw):$tmppath
  runex $zone."az$az".gw @"
  scp -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $tmppath test@10.21${az}.0.${id}:$dst
  rm $tmppath
"@
}

function pull($az,$id,$src,$dst){
  $tmppath = "/home/test/downloading"
  runex $zone."az$az".gw "scp -o ConnectTimeout=1 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no test@10.21${az}.0.${id}:$src $tmppath"
  scp -o ConnectTimeout=2 -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $tmp/private_key "test@$($zone."az$az".gw):$tmppath" $dst
  runex $zone."az$az".gw "rm $tmppath"
}
