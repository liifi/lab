terraform {
  required_providers {
    vsphere = {
      source = "hashicorp/vsphere"
      version = "2.2.0"
    }
  }
}

variable answers { type = any }

locals {
    _ = var.answers
    vms = flatten([ for zoneid,zonespec in local._.zone : [ for i,spec in zonespec.vm : merge(spec,{zone=zoneid, id="${zoneid}-n${split(".",spec.ips[0].ip)[length(split(".",spec.ips[0].ip))-1]}"}) if spec.enable ] ])
    alt_networks = { for alt_net in [ for net in flatten([ for vm in local.vms : [ for ip in vm.ips : try({name=ip.net,zone=vm.zone},null) ] ]) : net if net != null ] : "${alt_net.zone}-${alt_net.name}" => alt_net... }
}

provider "vsphere" {
  user                 = local._.vsphere_user
  password             = local._.vsphere_password
  vsphere_server       = local._.vsphere_server
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "all" {
  for_each      = local._.zone
  name = each.value.dc
}

data "vsphere_datastore" "all" {
  for_each      = local._.zone
  name          = each.value.data
  datacenter_id = data.vsphere_datacenter.all[each.key].id
}

data "vsphere_compute_cluster" "all" {
  for_each      = local._.zone
  name          = each.value.cluster
  datacenter_id = data.vsphere_datacenter.all[each.key].id
}

data "vsphere_network" "all" {
  for_each      = local._.zone
  name          = each.value.network
  datacenter_id = data.vsphere_datacenter.all[each.key].id
}

data "vsphere_network" "alt" {
  for_each      = local.alt_networks
  name          = each.value[0].name # Grouped by zone network, only 1 needed
  datacenter_id = data.vsphere_datacenter.all[each.value[0].zone].id # Grouped by zone network, only 1 needed
}

data "vsphere_virtual_machine" "ubuntu" {
  for_each      = local._.zone
  name          = each.value.ubuntu_template
  datacenter_id = data.vsphere_datacenter.all[each.key].id
}

resource "vsphere_virtual_machine" "vm" {
  for_each         = { for v in local.vms : v.id => v }
  name             = each.value.id
  enable_disk_uuid = true # Needed if using vsphere csi in kubernetes
  hardware_version = 15 # Needed if using vsphere csi in kubernetes, https://kb.vmware.com/s/article/2007240 (15 only support esxi 6.7 U2+ and above)
  datastore_id     = data.vsphere_datastore.all[each.value.zone].id
  resource_pool_id = data.vsphere_compute_cluster.all[each.value.zone].resource_pool_id
  num_cpus         = each.value.cpu
  memory           = each.value.memory * 1024
  guest_id         = data.vsphere_virtual_machine.ubuntu[each.value.zone].guest_id # "other3xLinux64Guest"
  scsi_type        = data.vsphere_virtual_machine.ubuntu[each.value.zone].scsi_type
  
  dynamic "network_interface" {
    for_each = each.value.ips
    content {
      network_id = try(data.vsphere_network.alt["${each.value.zone}-${network_interface.value.net}"].id, data.vsphere_network.all[each.value.zone].id)
      adapter_type = data.vsphere_virtual_machine.ubuntu[each.value.zone].network_interface_types[0]
    }
  }
  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.ubuntu[each.value.zone].disks.0.size
    thin_provisioned = data.vsphere_virtual_machine.ubuntu[each.value.zone].disks.0.thin_provisioned
  }
  clone {
    template_uuid = data.vsphere_virtual_machine.ubuntu[each.value.zone].id
    customize {
      linux_options {
        host_name = "${each.value.id}"
        domain = "host"
      }
      dynamic "network_interface" {
        for_each = each.value.ips
        content {
          ipv4_address = network_interface.value.ip
          ipv4_netmask = network_interface.value.ip_slash
          dns_server_list = [ network_interface.value.dns ]
        }
      }
      ipv4_gateway = each.value.gateway
    }
  }
  
  # If IPs are accessible authorized keys could be distributed like this, or they could already be present in the template too, instead use ./labs/00-ssh-keys.ps1
  # provisioner "file" {
  #   source      = "${module.path}/identity"
  #   destination = "/home/${local._.zone[each.value.zone].ubuntu_template_user}/.ssh/authorized_keys"

  #   connection {
  #     type     = "ssh"
  #     user     = local._.zone[each.value.zone].ubuntu_template_user
  #     password = local._.zone[each.value.zone].ubuntu_template_pass
  #     host     = each.value.ips[0].ip
  #   }
  # }

}


output "values" {
    value = [
        local.vms,
        data.vsphere_datacenter.all,
        data.vsphere_compute_cluster.all,
        data.vsphere_datastore.all,
        data.vsphere_network.all,
    ]
}