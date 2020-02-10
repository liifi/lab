# Configure the Rancher2 provider to bootstrap and admin
# Provider config for bootstrap
provider "rancher2" {
  alias = "bootstrap"

  api_url   = "https://rancher"
  bootstrap = true
  insecure = true
}

# Create a new rancher2_bootstrap using bootstrap provider config
resource "rancher2_bootstrap" "admin" {
  provider = "rancher2.bootstrap"

  password = "admin" # these labs are meant for testing
  telemetry = true
}

# Provider config for admin
provider "rancher2" {
  alias = "admin"

  api_url = "${rancher2_bootstrap.admin.url}"
  token_key = "${rancher2_bootstrap.admin.token}"
  insecure = true
}

# Create a new rancher2 resource using admin provider config
# resource "rancher2_catalog" "foo" {
#   provider = "rancher2.admin"

#   name = "test"
#   url = "http://foo.com:8080"
# }

# Create a new rancher2 RKE Cluster
resource "rancher2_cluster" "test-cluster" {
  provider = "rancher2.admin"
  name = "test-cluster"
  description = "test cluster created via terraform"
  rke_config {
    # NOTE:
    # THIS DOES NOT PROVISION, YOU ARE STILL INTENDED TO USE
    # THE OUTPUT COMMAND TO BE RAN ON MACHIENS
    # nodes {
    #   address = "node-1"
    #   user = "root"
    #   role = ["controlplane", "etcd", "worker"]
    #   ssh_agent_auth = true
    #   ssh_key_path = "/ws/identity"
    # }
    # network {
    #   plugin = "canal"
    # }
    # services {
    #   kube_api {
    #     audit_log {
    #       enabled = true
    #       configuration {
    #         max_age = 5
    #         max_backup = 5
    #         max_size = 100
    #         path = "-"
    #         format = "json"
    #         policy = jsonencode({"rules":[{"level": "Metadata"}]})
    #       }
    #     }
    #   }
    # }
  }
}