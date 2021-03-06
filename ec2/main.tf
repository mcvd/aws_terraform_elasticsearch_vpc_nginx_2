data "template_file" "bootstrap" {
  template = file("${path.module}/bootstrap.sh")

  vars = {
    es_cluster_address = var.es_cluster_address
  }
}

data "aws_iam_instance_profile" "default" {
  name = var.iam_profile_name
}

data "aws_kms_alias" "default" {
  name = var.kms_key_name
}

data "aws_ami" "default" {
  most_recent      = true
  owners           = ["self"]

  filter {
    name   = "name"
    values = [var.ami_name]
  }
}

resource "aws_instance" "default" {
  ami                    = data.aws_ami.default.image_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  key_name               = var.ssh_key_name
  associate_public_ip_address = false
  iam_instance_profile = join("", data.aws_iam_instance_profile.default.*.name)

  user_data = data.template_file.bootstrap.rendered

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "30"
    encrypted = true
    kms_key_id = data.aws_kms_alias.default.target_key_id
  }

  tags = {
    Environment = "TFTest"
    Name        = var.instance_name
  }

}
