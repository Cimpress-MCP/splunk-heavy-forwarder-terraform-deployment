resource "aws_security_group" "main" {
  name = "${var.name}-bastion-host-sg"
  description = "Security group for ${var.name} bastion host"
  vpc_id = var.vpc_id

  tags = merge({
    "Name" = "${var.name}-bastion-host-sg"
  }, var.tags)
}

# allow outgoing traffic
resource "aws_security_group_rule" "allow_all_outbound" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.main.id
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_instance" "bastion_host" {
  ami = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"
  key_name = var.ssh_key_name
  subnet_id = var.subnet_id
  vpc_security_group_ids = [aws_security_group.main.id]
  iam_instance_profile = var.instance_profile_name
  tags = merge({
    Name = "${var.name}-bastion-host"
  }, var.tags)
}
