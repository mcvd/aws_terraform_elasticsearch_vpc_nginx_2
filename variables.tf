variable "region" {
  default = "eu-west-2"
}

variable "domain_name" {
  default = "es-tf-test"
}

variable "cluster_automated_snapshot_start_hour" {
  default = 23
}

variable "cluster_instance_type" {
  # default = "i3.large.elasticsearch"
  default = "t2.small.elasticsearch"
}

variable "iam_profile_name" {
  default = "aqua-test-rds"
}

variable "ssh_key_name" {
  default = "kibana-sec-monitor"
}

variable "certificate_domain_name" {
  default = "*.755065139753.dev.awsbeta.jpmchase.net"
}

variable "kms_key_name" {
  default = "aws/ebs"
}
