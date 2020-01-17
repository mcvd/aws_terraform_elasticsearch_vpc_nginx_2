variable "region" {
  default = "eu-west-1"
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
