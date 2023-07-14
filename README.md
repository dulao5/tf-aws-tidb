# Terraform AWS TiDB Deployment

This repository contains Terraform code to deploy a TiDB cluster on Amazon Web Services (AWS). By using Terraform, you can automate the process of creating and managing resources on AWS, such as virtual machines, databases, and networking components. 

## Prerequisites

Before using this repository, make sure you have the following:

- An AWS account
- Terraform installed on your local machine
- Familiarity with Terraform syntax and AWS resources

## Getting Started

1. Clone this repository to your local machine.
2. Open the `variables.tf` file and modify the variables as needed to match your desired deployment configuration. You can also create a `.tfvars` file to specify values for the variables.
3. Run `terraform init` to download the required providers and initialize the Terraform working directory.
4. Run `terraform plan` to preview the changes that will be made to your AWS resources.
5. If the plan looks good, run `terraform apply` to apply the changes and deploy the TiDB cluster on AWS.

## Managing the Deployment

After deploying the TiDB cluster, you can use Terraform to make changes to the resources or manage the deployment. To update the cluster, modify the Terraform code, run `terraform plan`, and then run `terraform apply`. To destroy the cluster, run `terraform destroy`.

## Retrieving Output Information

After deploying the TiDB cluster with Terraform, you can use the `terraform output` command to retrieve important information about the deployment. The output includes the bastion IP (public IP) and the `tidb_bastion_keypair_private_key`, which is the SSH key.

```
terraform output -json | jq -r .tidb_bastion_keypair_private_key.value > ~/.ssh/tidb-test-bastion
chmod 600 ~/.ssh/tidb-test-bastion
```

To access the bastion host, use the following command, replacing `$bastion_ip` with the actual IP:

```
ssh -i $keyfile ec2-user@$bastion_ip

tiup --version

tiup cluster check tiup-topology.yaml
tiup cluster check tiup-topology.yaml --apply

tiup cluster deploy <cluster-name> <version> tiup-topology.yaml
tiup cluster start test-tidb --init
```
Once connected to the bastion host, you can use the `tiup cluster` subcommand to deploy the cluster components.


## Conclusion

With Terraform and AWS, you can easily deploy a TiDB cluster and manage the resources as needed. This repository provides a starting point for deploying a TiDB cluster on AWS, but you can customize the code to fit your specific requirements.
