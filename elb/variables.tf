variable "security_group_ids" {
  type    = list(string)
  default = []
}

variable "subnet_ids" {
  type    = list(string)
  default = []
}

variable "vpc_id" {
  type = string
}

variable "name" {
  type = string
}

variable "certificate_domain_name" {
  type = string
}

variable "instance_ids" {
  type = list(string)
}
