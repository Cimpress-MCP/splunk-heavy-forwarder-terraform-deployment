output "heavy_forwarder_instance_id" {
  description = "The instance id of the heavy forwarder"
  value = module.heavy_forwarder.instance_id
}

output "heavy_forwarder_public_ip" {
  description = "The public IP address of the heavy forwarder (will not exist if using a load balancer)"
  value = module.heavy_forwarder.public_ip
}

output "heavy_forwarder_private_ip" {
  description = "The private IP address of the heavy forwarder (needed for SSH through Bastion Host)"
  value = module.heavy_forwarder.private_ip
}

output "bastion_host_public_ip" {
  description = "The public IP address of the bastion host"
  value = module.bastion_host.public_ip
}
