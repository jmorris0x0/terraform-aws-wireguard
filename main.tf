data "template_file" "user_data" {
  template = file("${path.module}/templates/user-data.txt")

  vars = {
    wg_server_private_key = aws_ssm_parameter.wg_server_private_key.value
    wg_server_net         = var.wg_server_net
    wg_server_port        = var.wg_server_port
    peers                 = join("\n", data.template_file.wg_client_data_json.*.rendered)
    eip_id                = aws_eip.wireguard.id
  }
}

data "template_file" "wg_client_data_json" {
  template = file("${path.module}/templates/client-data.tpl")
  count    = length(var.wg_client_public_keys)

  vars = {
    client_pub_key       = element(values(var.wg_client_public_keys[count.index]), 0)
    client_ip            = element(keys(var.wg_client_public_keys[count.index]), 0)
    persistent_keepalive = var.wg_persistent_keepalive
  }
}

# We're using ubuntu images - this lets us grab the latest image for our region from Canonical
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-16.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

# turn the sg into a sorted list of string
locals {
  sg_wireguard_external = sort([aws_security_group.sg_wireguard_external.id])
  tunnel_string = templatefile("${path.module}/templates/tunnel.tpl", {
    wireguard_client_private_key = var.wireguard_client_private_key,
    wireguard_server_public_key  = var.wireguard_server_public_key,
    server_ip                    = aws_eip.wireguard.public_ip,
    persistent_keepalive         = var.wg_persistent_keepalive,
    wg_server_port               = var.wg_server_port
  })
  security_groups_ids = compact(concat(var.additional_security_group_ids, local.sg_wireguard_external))
}

resource "aws_launch_configuration" "wireguard_launch_config" {
  name_prefix                 = "wireguard-${var.env}-"
  image_id                    = var.ami_id == null ? data.aws_ami.ubuntu.id : var.ami_id
  instance_type               = var.instance_type
  spot_price                  = var.spot_price
  key_name                    = aws_key_pair.this.key_name
  iam_instance_profile        = aws_iam_instance_profile.wireguard_profile.name
  user_data                   = data.template_file.user_data.rendered
  security_groups             = local.security_groups_ids
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "wireguard_asg" {
  name                 = aws_launch_configuration.wireguard_launch_config.name
  launch_configuration = aws_launch_configuration.wireguard_launch_config.name
  min_size             = var.asg_min_size
  desired_capacity     = var.asg_desired_capacity
  max_size             = var.asg_max_size
  vpc_zone_identifier  = var.subnet_ids
  health_check_type    = "EC2"
  termination_policies = ["OldestLaunchConfiguration", "OldestInstance"]
  target_group_arns    = var.target_group_arns

  lifecycle {
    create_before_destroy = true
  }

  tags = [
    {
      key                 = "Name"
      value               = aws_launch_configuration.wireguard_launch_config.name
      propagate_at_launch = true
    },
    {
      key                 = "Project"
      value               = "wireguard"
      propagate_at_launch = true
    },
    {
      key                 = "env"
      value               = var.env
      propagate_at_launch = true
    },
    {
      key                 = "tf-managed"
      value               = "True"
      propagate_at_launch = true
    },
  ]
}

resource "aws_eip" "wireguard" {
  vpc = true
  tags = {
    Name = "wireguard"
  }
}


