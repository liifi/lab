$vagrant = "$PSScriptRoot/../.vagrant"
$tmp = "$vagrant/tmp"
New-Item -Force -Path $vagrant -Name "tmp" -ItemType "directory" -ErrorAction Ignore | Out-Null

function run($az,$id,$command){ ssh -t -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $vagrant/machines/az${az}-n${id}/hyperv/private_key vagrant@10.11${az}.${id} $command }
function push($az,$id,$src,$dst){ scp -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $vagrant/machines/az${az}-n${id}/hyperv/private_key $src vagrant@10.11${az}.${id}:$dst }
function pull($az,$id,$src,$dst){ scp -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $vagrant/machines/az${az}-n${id}/hyperv/private_key vagrant@10.11${az}.${id}:$src $dst }
