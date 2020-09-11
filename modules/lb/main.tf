data "aws_route53_zone" "default" {
  name = var.dns_zone
}

data "aws_acm_certificate" "cert" {
  domain = var.domain
}

resource "aws_lb" "main_alb" {
  name = "splunk-hfw-alb"

  internal = false
  enable_cross_zone_load_balancing = true
  idle_timeout = "60"
  load_balancer_type = "application"

  security_groups = [var.lb_security_group_id]
  subnets = var.subnet_ids
  enable_deletion_protection = false

  tags = merge(var.tags, {
    Name = "${var.name}-elb"
  })
}

#############################
# this covers HTTPS traffic #
#############################
resource "aws_lb_target_group" "main_https_tg" {
  name = "splunk-hfw-https-tg"
  port = 443
  protocol = "HTTPS"
  vpc_id = var.vpc_id

  health_check {
    protocol = "HTTPS"
    path = "/services/collector/health/1.0"
    interval = "15"
    healthy_threshold = "2"
    unhealthy_threshold = "2"
    timeout = "5"
  }

  tags = merge(var.tags, {
    Name = "${var.name}-https-tg"
  })
}

resource "aws_alb_target_group_attachment" "heavy_forwarder_http" {
  target_group_arn = aws_lb_target_group.main_https_tg.arn
  target_id = var.heavy_forwarder_instance_id
}

resource "aws_lb_listener" "main_alb_https" {
  load_balancer_arn = aws_lb.main_alb.arn
  port = "443"
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn = data.aws_acm_certificate.cert.arn

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.main_https_tg.arn
  }
}

###########################
# This covers HEC traffic #
###########################
# The HEC port doesn't have a health check so just use the HTTPS health check
resource "aws_lb_target_group" "main_hec_tg" {
  name = "splunk-hfw-hec-tg"
  port = 8088
  protocol = "HTTPS"
  vpc_id = var.vpc_id

  health_check {
    protocol = "HTTPS"
    path = "/services/collector/health/1.0"
    interval = "15"
    healthy_threshold = "2"
    unhealthy_threshold = "2"
    timeout = "5"
    port = "443"
  }

  tags = merge(var.tags, {
    Name = "${var.name}-hec-tg"
  })
}

resource "aws_alb_target_group_attachment" "heavy_forwarder_hec" {
  target_group_arn = aws_lb_target_group.main_hec_tg.arn
  target_id = var.heavy_forwarder_instance_id
}

resource "aws_lb_listener" "main_alb_hec" {
  load_balancer_arn = aws_lb.main_alb.arn
  port = "8088"
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn = data.aws_acm_certificate.cert.arn

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.main_hec_tg.arn
  }
}

################################
# This redirects HTTP to HTTPS #
################################
resource "aws_lb_listener" "main_alb_http" {
  load_balancer_arn = aws_lb.main_alb.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port = "443"
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_route53_record" "main_alb" {
  zone_id = data.aws_route53_zone.default.zone_id
  name = var.domain
  type = "A"

  alias {
    name = aws_lb.main_alb.dns_name
    zone_id = aws_lb.main_alb.zone_id
    evaluate_target_health = false
  }
}
