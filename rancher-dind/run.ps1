#!/usr/bin/env pwsh

Push-Location $PSScriptRoot
switch ($args[0]) {
  "init" { ./run.ps1 keygen; ./run.ps1 update }
  "keygen" { ssh-keygen -q -t rsa -f ./node/identity }
  "update" { docker-compose build; docker-compose up -d }
  "reset" { docker-compose down; docker-compose up -d }
  "core" { docker-compose exec core bash }
  "enter" { docker-compose exec "node-$($args[1])" bash }
  "sshlog" { docker-compose exec "node-$($args[1])" tail -f /var/log/auth.log }
  "ssh" { ssh -i ./node/identity -o StrictHostKeyChecking=no root@localhost -p "220$($args[1])" }
  "authorized" { docker-compose exec "node-$($args[1])" cat /root/.ssh/authorized_keys }
  "super" { docker run --rm -it --name enter -v /:/host --privileged --net=host --uts=host --pid=host --security-opt=seccomp=unconfined --entrypoint chroot alpine host }
  Default {
    Write-Host "Usage: ./run.ps1 <keygen|update|core|ssh|authorized|super>" -ForegroundColor Yellow
  }
}
Pop-Location