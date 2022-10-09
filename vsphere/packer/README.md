# What is this?

A basic ubuntu vm template creation for `vsphere` using `packer`

> Set variables of `.auto.pkrvars.hcl.example` and rename to `.auto.pkrvars.hcl`

```
packer build .
```


### Install packer

> If using Windows, then use WSL to run packer

```bash
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update
sudo apt-get install -y xorriso packer
```

---

### Cloudinit

Ubuntu can use cloud-config with a property `autoinstall` to automate the installation process, see these links to understand [./cloudinit-user-data.yaml](./cloudinit-user-data.yaml)

- https://ubuntu.com/server/docs/install/autoinstall-reference
- https://www.golinuxcloud.com/customize-cloud-init-user-data-ubuntu/

---

### Other builds
- https://github.com/tvories/packer-vsphere-hcl
- https://github.com/konstruktoid/hardened-images