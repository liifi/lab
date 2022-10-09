variable answers {}


source "vsphere-iso" "ubuntu" {
  # vCenter settings
  vcenter_server      = var.answers.vcenter_server
  username            = var.answers.vcenter_username
  password            = var.answers.vcenter_password
  insecure_connection = true
  cluster             = var.answers.vcenter_cluster
  datacenter          = var.answers.vcenter_datacenter
  datastore           = var.answers.vcenter_datastore
  convert_to_template = true
  
  # Requires a iso builder to be installed, like xorriso
  cd_label = "cidata" # Create an ISO labeled cidata (standard for cloudninit)
  # cd_files = ["vendor-data"] # In case other files are to be applied
  cd_content = {
    meta-data = jsonencode({})
    user-data = templatefile("cloudinit-user-data.yaml", {
      gateway = var.answers.gateway
      address = "${var.answers.ip}/${var.answers.ip_slash}"
      dns     = var.answers.dns
      user    = var.answers.user
      pass    = var.answers.pass
      pass_encrypted = var.answers.pass_encrypted
      # ssh_key_pub    = file("${path.folder}/identity.pub")
    })
  }

  # VM Settings
  vm_name             = var.answers.name
  CPUs                = var.answers.cpu
  cpu_cores           = var.answers.cores
  CPU_hot_plug        = true
  RAM                 = var.answers.memory * 1024
  RAM_hot_plug        = true

  # iso_paths           = [ var.answers.os_iso_path ]
  iso_url             = var.answers.iso_url
  iso_checksum        = var.answers.iso_checksum
  guest_os_type       = var.answers.guest_os_type
  # https://www.packer.io/plugins/builders/vsphere/vsphere-iso
  # If using ubuntu desktop then use this sequence
  # boot_command = [
  #   "<esc><enter><f6><esc><wait>",
  #   # " ip=${var.answers.ip}::${var.answers.gateway}:${var.answers.netmask}::::${var.answers.dns}", # In case static ip is needed to resolve http cloudinit
  #   " autoinstall ds='nocloud-net'", # ;s=http://...  to load cloud-init from some location
  #   " --- <enter>"
  # ]
  boot_command = [
    "c<wait>",
    "linux /casper/vmlinuz --- autoinstall ds='nocloud-net'<enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>",
  ]
  ssh_username           = var.answers.user
  ssh_password           = var.answers.pass
  ssh_port               = "22"
  ssh_handshake_attempts = "20"
  
  vm_version            = "13"
  disk_controller_type  = ["pvscsi"]
  network_adapters {
    network = var.answers.vm_network
    network_card = "vmxnet3"
  }
  storage {
    disk_size = var.answers.disk * 1000
    disk_thin_provisioned = true
  }

  # Timeouts
  ip_wait_timeout       = "20m"
  ssh_timeout           = "30m"
  shutdown_timeout      = "15m"
  boot_wait             = "5s"
}

build {
    sources = [
        "source.vsphere-iso.ubuntu",
    ]
    # provisioner "shell" {
    #   execute_command = "echo '${var.answers.pass}' | {{.Vars}} sudo -S -E sh -eux '{{.Path}}'" # This runs the scripts with sudo
    #   scripts = [
    #       "scripts/dosomething.sh",
    #   ]
    # }
}
