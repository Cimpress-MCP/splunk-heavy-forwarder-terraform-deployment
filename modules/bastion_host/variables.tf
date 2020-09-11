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

variable "subnet_id" {
  description = "The id of the subnet to deploy the forwarder into"
  type = string
}

variable "ssh_key_name" {
  description = "The name of the SSH key to include on the bastion host"
  type = string
}

variable "tags" {
  description = "(optional) Any additional tags to put on everything"
  type = map(string)
  default = {}
}
