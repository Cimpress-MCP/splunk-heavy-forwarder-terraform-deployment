# Put your desired region and the name of your AWS profile here:
provider "aws" {
  region = "us-east-1"
  profile = "[PROFILE_NAME]"
}

resource "aws_iam_role" "empty_instance_role" {
  name = "${var.name}-role"
  tags = var.tags
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Action": "sts:AssumeRole",
    "Principal": {"Service": "ec2.amazonaws.com"},
    "Effect": "Allow",
    "Sid": ""
  }]
}
EOF
}
resource "aws_iam_instance_profile" "empty_instance_profile" {
  name = "${var.name}-instance-profile"
  path = "/"
  role = aws_iam_role.empty_instance_role.name
}

module "lb_security_group" {
  source = "./modules/lb_security_group"
  name = var.name
  vpc_id = var.vpc_id
  tags = var.tags
}

module "bastion_host" {
  source = "./modules/bastion_host"
  name = var.name
  vpc_id = var.vpc_id
  subnet_id = var.public_subnet_id_1
  ssh_key_name = var.ssh_key_name
  instance_profile_name = aws_iam_instance_profile.empty_instance_profile.name
  tags = var.tags
}

module "heavy_forwarder" {
  source = "./modules/heavy_forwarder"
  name = var.name
  vpc_id = var.vpc_id
  subnet_id = var.public_subnet_id_1
  ssh_key_name = var.ssh_key_name
  splunk_admin_password = var.splunk_admin_password
  ami_name = var.ami_name
  instance_type = var.instance_type
  lb_security_group_id = module.lb_security_group.id
  bastion_host_security_group_id = module.bastion_host.security_group_id
  instance_profile_name = aws_iam_instance_profile.empty_instance_profile.name
  tags = var.tags
}

module "load_balancer" {
  source = "./modules/lb"
  name = var.name
  vpc_id = var.vpc_id
  subnet_ids = [var.public_subnet_id_1, var.public_subnet_id_2]
  tags = var.tags
  domain = var.domain
  dns_zone = var.dns_zone
  lb_security_group_id = module.lb_security_group.id
  heavy_forwarder_instance_id = module.heavy_forwarder.instance_id
}
