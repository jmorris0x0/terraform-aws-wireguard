locals {
  public_key_filename = format(
    "%s/%s%s",
    var.ssh_public_key_path,
    aws_key_pair.this.key_name,
    var.public_key_extension
  )

  private_key_filename = format(
    "%s/%s%s",
    var.ssh_public_key_path,
    aws_key_pair.this.key_name,
    var.private_key_extension
  )
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
}

resource "aws_key_pair" "this" {
  key_name   = "wireguard-ssh-key"
  public_key = tls_private_key.this.public_key_openssh
}

resource "local_file" "public_key_openssh" {
  depends_on = [tls_private_key.this]
  content    = tls_private_key.this.public_key_openssh
  filename   = local.public_key_filename
}

resource "local_file" "private_key_pem" {
  depends_on        = [tls_private_key.this]
  sensitive_content = tls_private_key.this.private_key_pem
  filename          = local.private_key_filename
  file_permission   = "0600"
}

