# vpc settings

# using terraform aws vpc module
# https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.3.0"

  name = "${var.name_prefix}-vpc-${var.aws_region}"

  cidr = var.aws_vpc_cidr

  azs             = var.aws_azs
  private_subnets = var.aws_private_subnets
  public_subnets  = var.aws_public_subnets

  enable_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = var.tags
}


module "security_group_bastion" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "${var.name_prefix}-bastion"
  description = "bastion(tiup) security group (allow 22 port)"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = var.bastion_allow_ssh_from
  ingress_rules       = ["ssh-tcp"]
  egress_rules        = ["all-all"]

  tags = var.tags
}

module "security_group_internal_tidb" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "${var.name_prefix}-internal-tidb"
  description = "tidb internal security group"
  vpc_id      = module.vpc.vpc_id

  // allow tidb internal traffic from self security group
  ingress_with_self = [
    {
        rule = "all-all"
    },
  ]

  // allow bastion ssh and tiup ports
  ingress_with_source_security_group_id = [
    {
      rule                     = "all-all"
      description              = "allow all from bastion"
      source_security_group_id = module.security_group_bastion.security_group_id
    }
  ]

  egress_rules      = ["all-all"]

  tags = var.tags
}

module "security_group_internal_tidb_load_balancer" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "${var.name_prefix}-internal-tidb-load-balancer"
  description = "tidb internal load balancer security group"
  vpc_id      = module.vpc.vpc_id

  // allow 4000 port from cidrs
  ingress_with_cidr_blocks = [
    {
        from_port   = 4000
        to_port     = 4000
        description = "tidb port"
        protocol    = "tcp"
        cidr_blocks = join(",", var.tidb_lb_allow_from)
    }
  ]

  egress_rules      = ["all-all"]

  tags = var.tags
}

# key pair settings

# using terraform aws key pair module
# https://registry.terraform.io/modules/terraform-aws-modules/key-pair/aws/latest
module "key_pair_tidb_bastion" {
  source  = "terraform-aws-modules/key-pair/aws"

  key_name   = "${var.name_prefix}-${var.aws_region}-bastion"
  create_private_key = true
}
module "key_pair_tidb_internal" {
  source  = "terraform-aws-modules/key-pair/aws"

  key_name   = "${var.name_prefix}-${var.aws_region}-internal"
  create_private_key = true
}

# ami settings

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# EC2 Module

# bastion ec2 instance
module "ec2_bastion"{
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "${var.name_prefix}-bastion"

  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.bastion_instance_type
  availability_zone           = var.aws_azs[0]
  subnet_id                   = element(module.vpc.public_subnets, 0)
  vpc_security_group_ids      = [module.security_group_bastion.security_group_id]
  associate_public_ip_address = true

  tags = var.tags

  enable_volume_tags = false
  root_block_device = [
    {
      volume_type = "gp3"
      volume_size = var.root_disk_size
      throughput  = 200
    }
  ]

  # key pair
  key_name = module.key_pair_tidb_bastion.key_pair_name

  # user data : init ~ec2-user/.ssh for login to internal tidb instances
  user_data = <<-EOF
    #!/bin/bash
    mkdir -p ~ec2-user/.ssh
    echo "${module.key_pair_tidb_internal.private_key_openssh}" > ~ec2-user/.ssh/id_rsa
    chmod 600 ~ec2-user/.ssh/id_rsa
    chown -R ec2-user:ec2-user ~ec2-user/.ssh
    sudo yum install -y mariadb-server 
  EOF
}

# internal tidb ec2 instances (limit var.tidb_count)
module "ec2_internal_tidb" {
  source = "terraform-aws-modules/ec2-instance/aws"
  
  count = var.tidb_count

  name = "${var.name_prefix}-internal-tidb-${count.index}"

  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.tidb_instance_type
  subnet_id                   = element(module.vpc.private_subnets, count.index % length(module.vpc.private_subnets))
  vpc_security_group_ids      = [module.security_group_internal_tidb.security_group_id, 
                                  module.security_group_internal_tidb_load_balancer.security_group_id]
  associate_public_ip_address = false
  key_name                    = module.key_pair_tidb_internal.key_pair_name

  tags = var.tags

  enable_volume_tags = false
  root_block_device = [
    {
      volume_type = "gp3"
      volume_size = var.root_disk_size
      throughput  = 200
    }
  ]
}

# internal tikv ec2 instances (limit var.tikv_count)
module "ec2_internal_tikv" {
  source = "terraform-aws-modules/ec2-instance/aws"
  
  count = var.tikv_count

  name = "${var.name_prefix}-internal-tikv-${count.index}"

  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.tikv_instance_type
  subnet_id                   = element(module.vpc.private_subnets, count.index % length(module.vpc.private_subnets))
  vpc_security_group_ids      = [module.security_group_internal_tidb.security_group_id]
  associate_public_ip_address = false
  key_name                    = module.key_pair_tidb_internal.key_pair_name

  tags = var.tags

  enable_volume_tags = false
  root_block_device = [
    {
      volume_type = "gp3"
      volume_size = var.root_disk_size
      throughput  = 200
    }
  ]
  ebs_block_device = [
    {
      device_name = "/dev/sdf"
      volume_type = "gp3"
      volume_size = var.tikv_data_disk_size
      throughput  = var.tikv_data_disk_throughput
    }
  ]

  # user data : init tikv data disk
  user_data = <<-EOF
    #!/bin/bash
    mkfs -t ext4 /dev/xvdf
    mkdir -p /data
    echo "/dev/xvdf /data ext4 defaults,nofail,noatime,nodelalloc 0 2" >> /etc/fstab
    mount -a
    chown -R ec2-user:ec2-user /data
  EOF
}

# internal pd ec2 instances (limit var.pd_count)
module "ec2_internal_pd" {
  source = "terraform-aws-modules/ec2-instance/aws"
  
  count = var.pd_count

  name = "${var.name_prefix}-internal-pd-${count.index}"

  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.pd_instance_type
  subnet_id                   = element(module.vpc.private_subnets, count.index % length(module.vpc.private_subnets))
  vpc_security_group_ids      = [module.security_group_internal_tidb.security_group_id]
  associate_public_ip_address = false
  key_name                    = module.key_pair_tidb_internal.key_pair_name

  tags = var.tags

  enable_volume_tags = false
  root_block_device = [
    {
      volume_type = "gp3"
      volume_size = var.root_disk_size
      throughput  = 200
    }
  ]
  ebs_block_device = [
    {
      device_name = "/dev/sdf"
      volume_type = "gp3"
      volume_size = var.pd_data_disk_size
      throughput  = var.pd_data_disk_throughput
    }
  ]

  user_data = <<-EOF
    #!/bin/bash
    mkfs -t ext4 /dev/xvdf
    mkdir -p /data
    echo "/dev/xvdf /data ext4 defaults,nofail,noatime,nodelalloc 0 2" >> /etc/fstab
    mount -a
    chown -R ec2-user:ec2-user /data
  EOF
}

// internal ticdc ec2 instances (limit var.ticdc_count)
module "ec2_internal_ticdc" {
  source = "terraform-aws-modules/ec2-instance/aws"
  
  count = var.ticdc_count

  name = "${var.name_prefix}-internal-ticdc-${count.index}"

  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.ticdc_instance_type
  subnet_id                   = element(module.vpc.private_subnets, count.index % length(module.vpc.private_subnets))
  vpc_security_group_ids      = [module.security_group_internal_tidb.security_group_id]
  associate_public_ip_address = false
  key_name                    = module.key_pair_tidb_internal.key_pair_name

  tags = var.tags

  enable_volume_tags = false
  root_block_device = [
    {
      volume_type = "gp3"
      volume_size = var.root_disk_size
      throughput  = 200
    }
  ]

  ebs_block_device = [
    {
      device_name = "/dev/sdf"
      volume_type = "gp3"
      volume_size = var.ticdc_data_disk_size
      throughput  = var.ticdc_data_disk_throughput
    }
  ]

  user_data = <<-EOF
    #!/bin/bash
    mkfs -t ext4 /dev/xvdf
    mkdir -p /data
    echo "/dev/xvdf /data ext4 defaults,nofail,noatime,nodelalloc 0 2" >> /etc/fstab
    mount -a
    chown -R ec2-user:ec2-user /data
  EOF
}

// internal one monitor ec2 instance
module "ec2_internal_monitor" {
  source = "terraform-aws-modules/ec2-instance/aws"
  
  count = 1

  name = "${var.name_prefix}-internal-monitor-${count.index}"

  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.monitor_instance_type
  subnet_id                   = element(module.vpc.private_subnets, count.index % length(module.vpc.private_subnets))
  vpc_security_group_ids      = [module.security_group_internal_tidb.security_group_id]
  associate_public_ip_address = false
  key_name                    = module.key_pair_tidb_internal.key_pair_name

  tags = var.tags

  enable_volume_tags = false
  root_block_device = [
    {
      volume_type = "gp3"
      volume_size = var.root_disk_size
      throughput  = 200
    }
  ]
}

// Load Balancer (NLB) (backend: internal tidb ec2 instances)
module "nlb_internal_tidb" {
  source              = "terraform-aws-modules/alb/aws"
  name                = "${var.name_prefix}-internal-nlb-tidb"
  load_balancer_type  = "network"
  vpc_id              = module.vpc.vpc_id
  subnets             = module.vpc.private_subnets
  internal            = true
  target_groups = [
    {
      name_prefix         = "nlb-"
      backend_protocol    = "TCP"
      backend_port        = 4000
      target_type         = "instance"
      preserve_client_ip  = false
      targets = {
        for i,instance in module.ec2_internal_tidb : 
          "target-${i}" => {
            target_id = instance.id
            port = 4000
          }
      }
    }
  ]
  http_tcp_listeners = [
    {
      port                = 4000
      protocol            = "TCP"
      target_group_index  = 0
    }
  ]

  depends_on = [
    module.ec2_internal_tidb
  ]
}

## make tidb cluster config from template
resource "local_file" "tidb_cluster_config" {
  content = templatefile("${path.module}/files/tiup-topology.yaml.tpl", {
    pd_private_ips: module.ec2_internal_pd.*.private_ip,
    tidb_private_ips: module.ec2_internal_tidb.*.private_ip,
    tikv_private_ips: module.ec2_internal_tikv.*.private_ip,
    ticdc_private_ips: module.ec2_internal_ticdc.*.private_ip,
    tiflash_private_ips: [],
    monitor_private_ip: element(module.ec2_internal_monitor.*.private_ip, 0),
  })
  filename = "${path.module}/tiup-topology.yaml"
  file_permission = "0644"
}

resource "local_file" "connect_script" {
  content = templatefile("${path.module}/files/connect.sh.tpl", {
    bastion_public_ip: module.ec2_bastion.public_ip,
    nlb_internal_tidb: module.nlb_internal_tidb.lb_dns_name
  })
  filename = "${path.module}/connect.sh"
  file_permission = "0755"
}

resource "null_resource" "bastion-inventory" {
  depends_on = [resource.local_file.tidb_cluster_config]

  # Changes to any instance of the bastion requires re-provisioning
  triggers = resource.local_file.tidb_cluster_config

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = "${module.key_pair_tidb_bastion.private_key_openssh}"
    host        = element(module.ec2_bastion.*.public_ip, 0)
  }

  provisioner "file" {
    source      = resource.local_file.tidb_cluster_config.filename
    destination = "/home/ec2-user/tiup-topology.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "curl --proto '=https' --tlsv1.2 -sSf https://tiup-mirrors.pingcap.com/install.sh | sh"
    ]
  }
}

