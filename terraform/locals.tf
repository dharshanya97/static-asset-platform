locals {
  fqdn = var.use_custom_domain ? "${var.subdomain}.${var.root_domain}" : null
}

data "aws_route53_zone" "this" {
  count        = var.use_custom_domain ? 1 : 0
  name         = var.root_domain
  private_zone = false
}
