provider "azure" {}

# Used to determine your public IP for forwarding rules
data "http" "whatismyip" {
  url = "http://whatismyip.akamai.com/"
}

locals {
  cluster_name = "sm-dev1"
}

module "dcos" {
  source  = "dcos-terraform/dcos/azurerm"
  version = "~> 0.2.0"

  providers = {
    aws = "azure"
  }

  location = "North Europe"

  cluster_name        = "${local.cluster_name}"
  ssh_public_key_file = "~/.ssh/aws-meso-wind.pub"
  admin_ips           = ["${data.http.whatismyip.body}/32"]

  num_masters        = "1"
  num_private_agents = "1"
  num_public_agents  = "1"

  dcos_instance_os        = "centos_7.6"
  bootstrap_instance_type = "m5.xlarge"

  dcos_variant              = "ee"
  dcos_version              = "1.13.0"
  dcos_license_key_contents = "${file("~/license.txt")}"
  ansible_bundled_container = "mesosphere/dcos-ansible-bundle:feature-windows-support-039d79d"

  # provide a SHA512 hashed password, here "deleteme"
  dcos_superuser_password_hash = "$6$rounds=656000$YSvuFmasQDXheddh$TpYlCxNHF6PbsGkjlK99Pwxg7D0mgWJ.y0hE2JKoa61wHx.1wtxTAHVRHfsJU9zzHWDoE08wpdtToHimNR9FJ/"
  dcos_superuser_username      = "demo-super"

  additional_windows_private_agent_ips       = ["${concat(module.winagent.private_ips)}"]
  additional_windows_private_agent_passwords = ["${concat(module.winagent.windows_passwords)}"]
}

module "winagent" {
  source  = "dcos-terraform/windows-instance/azurerm"
  version = "~>= 0.0.1"

  providers = {
    aws = "azure"
  }

  location = "North Europe"

  dcos_instance_os = "windows_1809"

  cluster_name           = "${local.cluster_name}"
  hostname_format        = "%[3]s-winagent%[1]d-%[2]s"

  num = "1"
}

output "masters_dns_name" {
  description = "This is the load balancer address to access the DC/OS UI"
  value       = "${module.dcos.masters-loadbalancer}"
}
