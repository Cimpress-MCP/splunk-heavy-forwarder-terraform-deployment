variable "name" {
  description = "A prefix to attach to all resources created by terraform"
  type = string
}

variable "instance_profile_name" {
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

variable "subnet_id" {
  description = "The id of the subnet to deploy the forwarder into"
  type = string
}

variable "ssh_key_name" {
  description = "The name of an SSH key to attach to the instances"
  type = string
}

variable "ami_name" {
  description = "The name of AMI for the heavy forwarder."
  type = string
}

variable "instance_type" {
  description = "The AWS instance type to use for the heavy forwarder."
  type = string
}

variable "bastion_host_security_group_id" {
  description = "The id of the security group for the bastion host"
  type = string
}

variable "lb_security_group_id" {
  description = "The id of the security group for the load balancer if in use"
  type = string
}

variable "tags" {
  description = "(optional) Any additional tags to put on everything"
  type = map(string)
  default = {}
}
