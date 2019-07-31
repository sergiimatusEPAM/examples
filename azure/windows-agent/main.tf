provider "azure" {}

# Used to determine your public IP for forwarding rules
data "http" "whatismyip" {
  url = "http://whatismyip.akamai.com/"
}

locals {
  cluster_name     = "sm-dev1"
  location         = "North Europe"
  dcos_version     = "1.13.0"
  dcos_variant     = "open"
  dcos_instance_os = "centos_7.6"
  dcos_winagent_os = "windows_1809"
  vm_size          = "Standard_D8s_v3"
  ssh_public_key_file = "~/.ssh/aws-meso-wind.pub"
}

module "dcos" {
  source  = "dcos-terraform/dcos/azurerm"
  version = "~> 0.2.0"

  providers = {
    azure = "azure"
  }

  location = "${local.location}"

  cluster_name        = "${local.cluster_name}"
  ssh_public_key_file = "${local.ssh_public_key_file}"
  admin_ips           = ["${data.http.whatismyip.body}/32"]

  num_masters        = "1"
  num_private_agents = "1"
  num_public_agents  = "1"

  dcos_instance_os        = "${local.dcos_instance_os}"

  dcos_variant              = "${local.dcos_variant}"
  dcos_version              = "1.13.0"
  dcos_license_key_contents = "${file("~/license.txt")}"
  ansible_bundled_container = "mesosphere/dcos-ansible-bundle:feature-windows-support-039d79d"

  # provide a SHA512 hashed password, here "deleteme"
  dcos_superuser_password_hash = "$6$rounds=656000$YSvuFmasQDXheddh$TpYlCxNHF6PbsGkjlK99Pwxg7D0mgWJ.y0hE2JKoa61wHx.1wtxTAHVRHfsJU9zzHWDoE08wpdtToHimNR9FJ/"
  dcos_superuser_username      = "demo-super"

  additional_windows_private_agent_ips       = ["${concat(module.winagent.private_ips)}"]
  #additional_windows_private_agent_passwords = ["${concat(module.winagent.windows_passwords)}"]
}

module "winagent" {
  source  = "dcos-terraform/windows-instance/azurerm"
  version = "0.0.1"

  providers = {
    azure = "azure"
  }

  location = "${local.location}"

  dcos_instance_os = "${local.dcos_winagent_os}"

  cluster_name           = "${local.cluster_name}"
  hostname_format        = "%[3]s-winagent%[1]d-%[2]s"

  subnet_id              = "${module.dcos.infrastructure.subnet_id}"
  resource_group_name    = "${module.dcos.infrastructure.resource_group_name}"
  vm_size                = "${local.vm_size}"
  admin_username         = "Administrator"
  public_ssh_key         = "${local.ssh_public_key_file}"

  num = "1"
}

output "masters_dns_name" {
  description = "This is the load balancer address to access the DC/OS UI"
  value       = "${module.dcos.masters-loadbalancer}"
}
