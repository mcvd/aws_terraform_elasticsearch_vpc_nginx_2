data "template_file" "bootstrap" {
  template = file("${path.module}/bootstrap.sh")

  vars = {
    es_cluster_address = var.es_cluster_address
  }
}

resource "aws_ebs_volume" "default" {
  availability_zone = "eu-west-1a"
  size              = 20
  encrypted = true
  kms_key_id = var.kms_key_id

  tags = {
    Name = "vol-${var.instance_name}"
  }
}


resource "aws_instance" "default" {
  ami                    = var.amis[var.region]
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  key_name               = var.kms_key_name
  associate_public_ip_address = false

  user_data = data.template_file.bootstrap.rendered

  ebs_block_device {
    device_name = "vol-${var.instance_name}"
    encrypted = true
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
