variable "name" {
  description = "A prefix to attach to all resources created by terraform"
  type = string
}

variable "vpc_id" {
  description = "The id of the VPC to put everything in"
  type = string
}

variable "tags" {
  description = "(optional) Any additional tags to put on everything"
  type = map(string)
  default = {}
}
