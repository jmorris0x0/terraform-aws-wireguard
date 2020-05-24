data "aws_caller_identity" "this" {}
data "aws_availability_zones" "available" {}

locals {
  name            = "main"
  vpc_cidr        = "10.66.0.0/16"
  vpc_subnet_bits = 8
  azs             = data.aws_availability_zones.available.names
  public_subnets = [for netnum in range(length(local.azs)) :
  cidrsubnet(local.vpc_cidr, local.vpc_subnet_bits, netnum)]
  private_subnets = [for netnum in range(length(local.azs)) :
  cidrsubnet(local.vpc_cidr, local.vpc_subnet_bits, netnum + 100)]
}

module "vpc" {
  source                 = "terraform-aws-modules/vpc/aws"
  version                = "2.21.0"
  name                   = local.name
  cidr                   = local.vpc_cidr
  azs                    = local.azs
  private_subnets        = local.private_subnets
  public_subnets         = local.public_subnets
  enable_nat_gateway     = false
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  enable_dns_hostnames   = true
}

module "wireguard" {
  source                       = "../../"
  vpc_id                       = module.vpc.vpc_id
  subnet_ids                   = module.vpc.public_subnets
  wg_server_net                = "192.168.2.1/24" # client IPs MUST exist in this net
  wireguard_server_private_key = "foo"
  wireguard_server_public_key  = "bar"

  wg_client_public_keys = [
    { "192.168.2.2/32" = "QFX/DXxUv56mleCJbfYyhN/KnLCrgp7Fq2fyVOk/FWU=" }, # make sure these are correct
    { "192.168.2.3/32" = "+IEmKgaapYosHeehKW8MCcU65Tf5e4aXIvXGdcUlI0Q=" }, # wireguard is sensitive
    { "192.168.2.4/32" = "WO0tKrpUWlqbl/xWv6riJIXipiMfAEKi51qvHFUU30E=" }, # to bad configuration
  ]
}


#variable "wireguard_client_private_key" {
#description = <<-EOT

#EOT
#type        = string
#}

#variable "wireguard_client_public_key" {
#description = <<-EOT

#EOT
#type        = string
#}


