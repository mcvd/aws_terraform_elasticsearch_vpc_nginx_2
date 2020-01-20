provider "aws" {
  profile = "adfs"
  region  = var.region
}

# GET REGION AND IDENTITY
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# VPC
data "aws_vpc" "spoke" {
  id = "vpc-0f8852212761af9e8"
}

# SUBNETS
data "aws_subnet" "private_a" {
  id = "subnet-08ff0fd88422411a5"
}

data "aws_subnet" "private_b" {
  id = "subnet-0a681899469e77ba5"
}

data "aws_subnet" "public_a" {
  id = "subnet-031363da59d946bb0"
}

data "aws_subnet" "public_b" {
  id = "subnet-02a97bb2144d004ad"
}


# Security group to access
resource "aws_security_group" "public_to_private" {
  name   = "es-cluster-security-monitor"
  vpc_id = data.aws_vpc.spoke.id

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["100.68.73.0/26", "100.68.73.64/26"]
  }

  # HTTPS access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["100.68.73.0/26", "100.68.73.64/26"]
  }

  # ICMP access from anywhere
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icpm"
    cidr_blocks = ["100.68.73.0/26", "100.68.73.64/26"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_security_group" "default" {
  id = "sg-0b102a0dc85bd719a"
}

data "aws_security_group" "edge" {
  id = "sg-068373d555607f272"
}

data "aws_security_group" "endpoint" {
  id = "sg-02b0db7f2ea2af5f5"
}

# CREATE THE ES CLUSTER
# resource "aws_elasticsearch_domain" "es" {
#   domain_name           = var.domain_name
#   elasticsearch_version = "7.1"

#   node_to_node_encryption {
#     enabled = true
#   }

#   # encrypt_at_rest {
#   #   enabled = true
#   # }

#   cluster_config {
#     instance_type = var.cluster_instance_type
#     # dedicated_master_count   = 3
#     # dedicated_master_enabled = true
#     # dedicated_master_type    = var.cluster_instance_type
#     # instance_count           = "4"
#     instance_count         = "2"
#     zone_awareness_enabled = true
#   }
#   ebs_options {
#     ebs_enabled = true

#     # volume_type = "io1"
#     volume_type = "gp2"
#     volume_size = 10

#     # iops        = 300
#   }
#   vpc_options {
#     subnet_ids         = list(data.aws_subnet.private_a.id, data.aws_subnet.private_b.id)
#     security_group_ids = list(data.aws_security_group.endpoint.id)
#   }
#   access_policies = <<CONFIG
#   {
#     "Version": "2012-10-17",
#     "Statement": [
#       {
#         "Effect": "Allow",
#         "Principal": {
#           "AWS": [
#             "*"
#           ]
#         },
#         "Action": [
#           "es:*"
#         ],
#         "Resource": "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.domain_name}/*"
#       }
#     ]
#   }
#   CONFIG
#   snapshot_options {
#     automated_snapshot_start_hour = var.cluster_automated_snapshot_start_hour
#   }
#   tags = {
#     Domain = var.domain_name
#   }
# }

# KMS Key to encrypt EBS + Access EC2
data "aws_kms_key" "default" {
  key_id = "arn:aws:kms:eu-west-1:755065139753:key/5e058be4-cea8-4438-b80c-330f1867e461"
}

# CREATING ALB AND EC2 NGINX REVERSE PROXY INSTANCES
module "alb" {
  source             = "./alb"
  security_group_ids = list(data.aws_security_group.default.id, data.aws_security_group.edge.id)
  subnet_ids         = list(data.aws_subnet.public_a.id, data.aws_subnet.public_b.id)
  vpc_id             = data.aws_vpc.spoke.id
  name               = "es-alb"
  certificate_arn    = var.certificate_arn
}

module "ec2_a" {
  source              = "./ec2"
  instance_name       = "es-nginx-a"
  region              = var.region
  subnet_id           = data.aws_subnet.private_a.id
  security_group_ids  = list(aws_security_group.public_to_private.id)
  lb_target_group_arn = module.alb.lb_target_group_arn
  # es_cluster_address  = aws_elasticsearch_domain.es.endpoint
  es_cluster_address  = "A"
  ssh_key_name        = var.ssh_key_name
  kms_key_id          = data.aws_kms_key.default.arn
  iam_profile_name    = var.iam_profile_name
}

module "ec2_b" {
  source              = "./ec2"
  instance_name       = "es-nginx-b"
  region              = var.region
  subnet_id           = data.aws_subnet.private_b.id
  security_group_ids  = list(aws_security_group.public_to_private.id)
  lb_target_group_arn = module.alb.lb_target_group_arn
  # es_cluster_address  = aws_elasticsearch_domain.es.endpoint
  es_cluster_address  = "B"
  ssh_key_name        = var.ssh_key_name
  kms_key_id          = data.aws_kms_key.default.arn
  iam_profile_name    = var.iam_profile_name
}

# CREATE VPC ENDPOINT
# resource "aws_vpc_endpoint" "default" {
#   vpc_id            = data.aws_vpc.spoke.id
#   service_name      = "com.amazonaws.${data.aws_region.current.name}.elasticloadbalancing"
#   vpc_endpoint_type = "Interface"

#   security_group_ids = list(data.aws_security_group.default.id)

#   subnet_ids = list(data.aws_subnet.private_b.id, data.aws_subnet.private_a.id)

#   private_dns_enabled = true
# }
