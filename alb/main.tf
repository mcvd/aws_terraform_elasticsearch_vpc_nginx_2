resource "aws_elb" "default" {
  internal           = true
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids

  instances = var.instance_ids

  listener {
    instance_port      = 80
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = var.certificate_arn
  }

  tags = {
    Environment = "TFTest"
    Name        = var.name
    HostName = "kibana-test"
  }
}
