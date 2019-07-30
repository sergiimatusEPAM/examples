# ALPHA STATE - DO NOT USE THIS EXAMPLE

(Change for Azure)

This is an early example how to use and integrate windows agents. If you're not
an active developer of this project we do not suggest to use it.

## Terraform usage

You need our Terraformfile based terraform 0.11 fork: https://github.com/fatz/terraform/releases/tag/v0.11.14-mesosphere

```
terraform init -upgrade
terraform apply
```

wait for the cluster to be spawned.
It will also spin up a windows instance and uses the `ansible_bundled_container` docker image.

The `ansible_bundled_container` can be replaced with your own provided docker image, to test the ansible run
which is fully integrated into the terraform apply process.
It will be pulled onto the bootstrap node and being executed there.
