data "template_file" "bootstrap" {
  template = file("${path.module}/bootstrap.sh")

  vars = {
    es_cluster_address = var.es_cluster_address
  }
}

data "aws_iam_instance_profile" "default" {
  name = var.iam_profile_name
}

resource "aws_instance" "default" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  key_name               = var.kms_key_name
  associate_public_ip_address = false
  iam_instance_profile = join("", data.aws_iam_instance_profile.default.*.name)

  user_data = data.template_file.bootstrap.rendered

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "30"
    encrypted = true
    kms_key_id = var.kms_key_id
  }

  tags = {
    Environment = "TFTest"
    Name        = var.instance_name
  }
}

resource "aws_lb_target_group_attachment" "default" {
  target_group_arn = var.lb_target_group_arn
  target_id        = aws_instance.default.id
  port             = 80
}
