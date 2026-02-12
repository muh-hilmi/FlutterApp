# Application Load Balancer
resource "aws_lb" "anigmaa_alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets           = aws_subnet.public_subnets[*].id

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# Target Group
resource "aws_lb_target_group" "anigmaa_backend" {
  name        = "${var.project_name}-backend-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.anigmaa_vpc.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-backend-tg"
  }
}

# ALB Listener (HTTP) - May already exist from previous deployment
# Commented out to avoid "DuplicateListener" error if already created
# Uncomment if needed for fresh deployment without existing ALB
/*
resource "aws_lb_listener" "anigmaa_backend" {
  load_balancer_arn = aws_lb.anigmaa_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
*/

# ALB Listener (HTTPS) - Only create if certificate ARN is provided
resource "aws_lb_listener" "anigmaa_backend_https" {
  count             = var.certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.anigmaa_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.anigmaa_backend.arn
  }
}

# ALB Listener Rule for HTTP (if no HTTPS certificate)
resource "aws_lb_listener" "anigmaa_backend_http_only" {
  count             = var.certificate_arn == "" ? 1 : 0
  load_balancer_arn = aws_lb.anigmaa_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.anigmaa_backend.arn
  }
}