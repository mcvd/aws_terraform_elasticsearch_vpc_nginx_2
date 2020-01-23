provider "aws" {
  profile = "adfs"
  region  = var.region
}

# GET REGION AND IDENTITY
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# VPC
data "aws_vpc" "spoke" {
  filter {
    name   = "tag:Name"
    values = ["Spoke VPC"]
  }
}

# SUBNETS
data "aws_subnet" "private_a" {
  filter {
    name   = "tag:Name"
    values = ["PrivateSubnet01"]
  }
}

data "aws_subnet" "private_b" {
  filter {
    name   = "tag:Name"
    values = ["PrivateSubnet02"]
  }
}

data "aws_subnet" "public_a" {
  filter {
    name   = "tag:Name"
    values = ["PublicSubnet01"]
  }
}

data "aws_subnet" "public_b" {
  filter {
    name   = "tag:Name"
    values = ["PublicSubnet02"]
  }
}


# Security groups
data "aws_security_group" "default" {
  name = "default"
}

data "aws_security_group" "edge" {
  name = "EdgeSecurityGroup"
}

data "aws_security_group" "endpoint" {
  name = "endpoint-security-group"
}

# CREATE THE ES CLUSTER
resource "aws_elasticsearch_domain" "es" {
  domain_name           = var.domain_name
  elasticsearch_version = "7.1"

  node_to_node_encryption {
    enabled = true
  }

  # encrypt_at_rest {
  #   enabled = true
  # }

  cluster_config {
    instance_type = var.cluster_instance_type
    # dedicated_master_count   = 3
    # dedicated_master_enabled = true
    # dedicated_master_type    = var.cluster_instance_type
    # instance_count           = "4"
    instance_count         = "2"
    zone_awareness_enabled = true
  }
  ebs_options {
    ebs_enabled = true

    # volume_type = "io1"
    volume_type = "gp2"
    volume_size = 10

    # iops        = 300
  }
  vpc_options {
    subnet_ids         = list(data.aws_subnet.private_a.id, data.aws_subnet.private_b.id)
    security_group_ids = list(data.aws_security_group.endpoint.id)
  }
  access_policies = <<CONFIG
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": [
            "*"
          ]
        },
        "Action": [
          "es:*"
        ],
        "Resource": "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.domain_name}/*"
      }
    ]
  }
  CONFIG
  snapshot_options {
    automated_snapshot_start_hour = var.cluster_automated_snapshot_start_hour
  }
  tags = {
    Domain = var.domain_name
  }
}

# CREATING ELB AND EC2 NGINX REVERSE PROXY INSTANCES

module "ec2_a" {
  source             = "./ec2"
  instance_name      = "es-nginx-a"
  region             = var.region
  subnet_id          = data.aws_subnet.private_a.id
  security_group_ids = list(data.aws_security_group.default.id)
  es_cluster_address = aws_elasticsearch_domain.es.endpoint
  ssh_key_name       = "${var.region}-${var.ssh_key_name}"
  kms_key_name       = var.kms_key_name
  iam_profile_name   = var.iam_profile_name
}

module "ec2_b" {
  source             = "./ec2"
  instance_name      = "es-nginx-b"
  region             = var.region
  subnet_id          = data.aws_subnet.private_b.id
  security_group_ids = list(data.aws_security_group.default.id)
  es_cluster_address = aws_elasticsearch_domain.es.endpoint
  ssh_key_name       = "${var.region}-${var.ssh_key_name}"
  kms_key_name       = var.kms_key_name
  iam_profile_name   = var.iam_profile_name
}

module "elb" {
  source                  = "./elb"
  security_group_ids      = list(data.aws_security_group.default.id, data.aws_security_group.edge.id)
  subnet_ids              = list(data.aws_subnet.public_a.id, data.aws_subnet.public_b.id)
  vpc_id                  = data.aws_vpc.spoke.id
  name                    = "es-elb"
  certificate_domain_name = var.certificate_domain_name
  instance_ids            = list(module.ec2_a.instance_id, module.ec2_b.instance_id)
}

module "lambda" {
  source = "./lambda"
}

module "s3" {
  source = "./s3"
}

resource "aws_lambda_event_source_mapping" "s3_to_es" {
  event_source_arn  = module.s3.arn
  function_name     = module.lambda.arn
}
