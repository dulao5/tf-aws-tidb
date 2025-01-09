# aws configure

# name prefix
variable "name_prefix" {
  type        = string
  default     = "tidb-test"
  description = "tidb-test"
}

# aws region
variable "aws_region" {
  type        = string
  default     = "ap-northeast-1"
  description = "AWS Region"
}

variable "aws_azs" {
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
  description = "AWS Availability Zones"
}
  
variable "aws_vpc_cidr" {
  type        = string
  default     = "172.20.0.0/16"
  description = "AWS VPC CIDR"
}

variable "aws_private_subnets" {
  type        = list(string)
  default     = ["172.20.1.0/24", "172.20.2.0/24", "172.20.3.0/24"]
  description = "AWS Private Subnets"
}

variable "aws_public_subnets" {
  type        = list(string)
  default     = ["172.20.101.0/24", "172.20.102.0/24", "172.20.103.0/24"]
  description = "AWS Public Subnets"
}

## tidb configs

## servers spec

variable "tidb_instance_type" {
 type    = string
 default = "c6g.2xlarge" // on tidbcloud : 8C16G/c6.2xlarge , 16C32G/c6.4xlarge
}

variable "tikv_instance_type" {
  type    = string
  default = "m6g.2xlarge" // on tidbcloud : 8C32G/m6.2xlarge , 16C64G/m6.4xlarge
}

variable "pd_instance_type" {
  type    = string
  default = "c6g.xlarge" // on tidbcloud : 4C/c6.xlarge , 8C/c6.2xlarge
}

variable "monitor_instance_type" {
  type    = string
  default = "t4g.medium"
}

variable "ticdc_instance_type" {
  type    = string
  default = "t4g.medium"
}

variable "bastion_instance_type" {
  type    = string
  default = "c6g.2xlarge"
}

## servers disk 

variable "root_disk_size" {
  type    = number
  default = 150
}

variable "tikv_data_disk_size" {
  type    = number
  default = 500
}

variable "tikv_data_disk_iops" {
  type   = number
  default = 4000 # default 4000 on tidbcloud
}

variable "tikv_data_disk_throughput" {
  type    = number
  default = 288 # default 288MB/s on tidbcloud
}

variable "pd_data_disk_size" {
  type    = number
  default = 200
}

variable "pd_data_disk_throughput" {
  type    = number
  default = 200
}

variable "ticdc_data_disk_size" {
  type    = number
  default = 200
}

variable "ticdc_data_disk_throughput" {
  type    = number
  default = 200
}

## servers count

variable "tidb_count" {
	type = number
	description = "The numble of the tidb instances to be deployed"
	default = 2
}

variable "tikv_count" {
	type = number
	description = "The numble of the tikv instances to be deployed"
	default = 3
}

variable "pd_count" {
	type = number
	description = "The numble of the pd instances to be deployed"
	default = 3
}

variable "ticdc_count" {
  type = number
  description = "The numble of the ticdc worker instances to be deployed"
  default = 0
}

## tags 

variable "tags" {
    type = map(string)
    default = {
        "Owner" = "tf-aws-tidb",
        "Project" = "AWS TiDB Cluster",
        "Environment" = "test",
    }
    description = "The tags to be added to the resources"
}

## bastion allow ssh from
variable "bastion_allow_ssh_from" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
## internal tidb lb allow from
variable "tidb_lb_allow_from" {
  type        = list(string)
  default     = ["172.20.0.0/16"]
}
