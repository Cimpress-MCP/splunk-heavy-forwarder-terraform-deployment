variable "name" {
  description = "A prefix to attach to all resources created by terraform"
  type = string
}

variable "vpc_id" {
  description = "The id of the VPC to put everything in"
  type = string
}

variable "subnet_ids" {
  description = "The ids of the public subnets to put the load balancer in"
  type = list(string)
}

variable "lb_security_group_id" {
  description = "The security group id to use for the load balancer"
  type = string
}

variable "heavy_forwarder_instance_id" {
  description = "The instance id of the heavy forwarder"
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

variable "tags" {
  description = "(optional) Any additional tags to put on everything"
  type = map(string)
  default = {}
}
