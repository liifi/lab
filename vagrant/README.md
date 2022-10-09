
# What is this

A [Vagrantfile](https://www.vagrantup.com/) for Windows Hyper-V sandbox

- Ubuntu nodes
- [Workaround](https://www.vagrantup.com/docs/v2.2.19/providers/hyperv/limitations) for Static IPs
- 3 Availability Zones
- AZs are separated by subnet/switch and Windows acts as the gateway (NAT and Router)

# How to use

- Ensure you have [Hyper-V](https://www.vagrantup.com/docs/v2.2.19/providers/hyperv) active
- Review `servers` in [Vagrantfile](./Vagrantfile)
- Open powershell as Administrator
- Run
  ```powershell
  vagrant plugin install vagrant-reload
  vagrant up --parallel
  ```
- When prompted, select `Default Switch` so Vagrant can run provision scripts on first boot
- The VMs will then reboot after provision and boot on the proper AZ network

# How to destroy
- Open powershell as Administrator
- Run
  ```powershell
  vagrant destroy --parallel
  ```

# Notes

### Router

Windows by default does not do routing between internal switches

> Run the following as administrator

```powershell
Set-ItemProperty -Path HKLM:\system\CurrentControlSet\services\Tcpip\Parameters -Name IpEnableRouter -Value 1
Restart-Computer
```
