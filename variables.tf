variable "name" {
  description = "A prefix to attach to all resources created by terraform"
  type = string
}

variable "vpc_id" {
  description = "The id of the VPC to put everything in"
  type = string
}

variable "splunk_admin_password" {
  description = "The admin password to set for splunk"
  type = string
}

variable "public_subnet_id_1" {
  description = "The id of the public subnet to put the bastion host and/or the splunk forwarder in"
  type = string
}

variable "public_subnet_id_2" {
  description = "The id of a second public subnet (application load balancers require 2 subnets)"
  type = string
}

variable "ssh_key_name" {
  description = "The name of an SSH key to attach to the instances"
  type = string
}

variable "domain" {
  description = "The domain name to host the LB at.  You will also have to create an SSL certificate in AWS for the domain name."
  type = string
}

variable "dns_zone" {
  description = "The DNS zone that the domain name is hosted in"
  type = string
}

variable "ami_name" {
  description = "(optional) The name of AMI for the heavy forwarder.  If not provided it will default to the CimSec AMI, but you need to let us know so we can give your AWS account permission to use it.  Otherwise you must build your own AMI (We have a Packer repo for that too)."
  type = string
  default = "splunk_heavy_forwarder_aws_linux_8.0.5"
}

variable "instance_type" {
  description = "(optional) The AWS instance type to use for the heavy forwarder.  Defaults to t3a.xlarge"
  type = string
  default = "t3a.xlarge"
}

variable "tags" {
  description = "(optional) Any additional tags to put on everything"
  type = map(string)
  default = {}
}
