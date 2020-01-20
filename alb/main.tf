resource "aws_lb" "default" {
  internal           = true
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids

  tags = {
    Environment = "TFTest"
    Name        = var.name
    HostName = "kibana-test"
  }
}

# resource "aws_lb_target_group" "default" {
#   port     = 80
#   protocol = "HTTP"
#   vpc_id   = var.vpc_id

#   health_check {
#     path                = "/_plugin/kibana"
#     matcher             = "200"
#     healthy_threshold   = "2"
#     unhealthy_threshold = "2"
#   }

#   tags = {
#     Environment = "TFTest"
#     Name        = "tft-alb-tg"
#   }
# }

resource "aws_lb_target_group" "https" {
  port     = 443
  protocol = "HTTPS"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/_plugin/kibana"
    matcher             = "200"
    healthy_threshold   = "2"
    unhealthy_threshold = "2"
  }

  tags = {
    Environment = "TFTest"
    Name        = "tft-alb-tg-https"
    HostName = "kibana-test"
  }
}

# resource "aws_lb_listener" "default" {
#   load_balancer_arn = aws_lb.default.arn
#   port              = "80"
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.default.arn
#   }
# }

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.default.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.https.arn
  }
}
