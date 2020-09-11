output "instance_id" {
  description = "The instance id of the heavy forwarder"
  value = aws_instance.heavy_forwarder.id
}

output "public_ip" {
  description = "The public IP address of the heavy forwarder (will not exist if using a load balancer)"
  value = aws_instance.heavy_forwarder.public_ip
}

output "private_ip" {
  description = "The private IP address of the heavy forwarder (needed for SSH through bastion host)"
  value = aws_instance.heavy_forwarder.private_ip
}
