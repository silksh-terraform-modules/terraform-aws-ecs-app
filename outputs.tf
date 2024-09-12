output "app_fqdn" {
  value = var.service_dns_name
}

output "app_fqdn_secondary" {
  value = aws_route53_record.secondary[*].fqdn
}

output "aws_lb_target_group_arn" {
  value = aws_lb_target_group.this[0].arn
}

variable "security_header" {
  type = object({
    header_name   = string
    values = list(string)
  })
  default = null
}

variable "security_header_secondary" {
  type = object({
    header_name   = string
    values = list(string)
  })
  default = null
}