
# What is this

A setup using [Terraform](https://www.terraform.io) and [Packer](https://www.packer.io) to create a **VMware Vsphere** sandbox

- Ubuntu nodes
- 3 Availability Zones
- AZs should be separated by subnet/switch and can use some nodes as routers or [OPNsense](https://opnsense.org)

# How to use

- Create a vm template with these [packer instructions](./packer/)
- Create a vms with these [terraform instructions](./terraform/)
- Run the labs [labs](./terraform/labs/)

# Notes

### Router

- TBD
