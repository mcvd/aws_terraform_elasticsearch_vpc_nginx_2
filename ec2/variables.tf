variable "region" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
}

variable "lb_target_group_arn" {
  type = string
}

variable "es_cluster_address" {
  type = string
}

variable "kms_key_id" {
  type = string
}

variable "amis" {
  type = map

  default = {
    "eu-west-1" = "ami-01f14919ba412de34"
  }
}

variable "ami" {
  type = string
  default = "ami-003c7a2caadbcda1f"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "instance_name" {
  type    = string
  default = "myinstance"
}

variable "kms_key_name" {
  type    = string
  default = "TFTest"
}
