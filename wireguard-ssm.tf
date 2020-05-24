resource "aws_ssm_parameter" "wg_server_private_key" {
  name  = var.wg_server_private_key_param
  type  = "SecureString"
  value = var.wireguard_server_private_key
}
