output "vpn_sg_admin_id" {
  value       = aws_security_group.sg_wireguard_admin.id
  description = "ID of the internal Security Group to associate with other resources needing to be accessed on VPN."
}

output "vpn_sg_external_id" {
  value       = aws_security_group.sg_wireguard_external.id
  description = "ID of the external Security Group to associate with the VPN."
}

output "vpn_asg_name" {
  value       = aws_autoscaling_group.wireguard_asg.name
  description = "ID of the internal Security Group to associate with other resources needing to be accessed on VPN."
}

output "ssh_private_key_pem" {
  value = tls_private_key.this.private_key_pem
}

output "eip_public_ip" {
  value = aws_eip.wireguard.public_ip
}

output "tunnel_string" {
  description = <<-EOT
    Tunnel data to enter into WireGuard on client machine.
  EOT
  value       = local.tunnel_string
}
