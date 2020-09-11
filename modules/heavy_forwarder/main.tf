resource "aws_security_group" "heavy_forwarder" {
  name = "${var.name}-sg"
  description = "Security group for ${var.name}"
  vpc_id = var.vpc_id

  tags = merge({
    "Name" = "${var.name}-security-group"
  }, var.tags)
}

resource "aws_security_group_rule" "allow_all_outbound" {
  description = "Outgoing traffic"
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.heavy_forwarder.id
}

resource "aws_security_group_rule" "allow_ssh_from_bastion_host" {
  description = "SSH from bastion host"
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  source_security_group_id = var.bastion_host_security_group_id
  security_group_id = aws_security_group.heavy_forwarder.id
}

resource "aws_security_group_rule" "allow_lb_https_inbound" {
  description = "HTTPS inbound from load balancer"
  type = "ingress"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  source_security_group_id = var.lb_security_group_id
  security_group_id = aws_security_group.heavy_forwarder.id
}

resource "aws_security_group_rule" "allow_lb_hec_inbound" {
  description = "HEC inbound from load balancer"
  type = "ingress"
  from_port = 8088
  to_port = 8088
  protocol = "tcp"
  source_security_group_id = var.lb_security_group_id
  security_group_id = aws_security_group.heavy_forwarder.id
}

data "aws_ami" "heavy_forwarder" {
  most_recent = true
  owners = ["self"]

  filter {
    name = "name"
    values = [var.ami_name]
  }
}

data "template_file" "startup_script" {
  template = file("${path.module}/startup_script.sh")

  vars = {
    splunk_admin_password = var.splunk_admin_password
  }
}

resource "aws_instance" "heavy_forwarder" {
  ami = data.aws_ami.heavy_forwarder.id
  instance_type = var.instance_type
  subnet_id = var.subnet_id
  key_name = var.ssh_key_name
  vpc_security_group_ids = [aws_security_group.heavy_forwarder.id]
  user_data = data.template_file.startup_script.rendered
  iam_instance_profile = var.instance_profile_name

  root_block_device {
    volume_size = "100"
    encrypted = true
  }

  tags = merge({
    "Name" = var.name
  }, var.tags)
}
