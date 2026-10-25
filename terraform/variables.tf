variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "use_custom_domain" {
  description = "false = use the free xxxx.cloudfront.net URL. true = custom domain via Route53 + ACM."
  type        = bool
  default     = false
}

variable "root_domain" {
  description = "Existing Route53 public hosted zone, e.g. example.com (only used if use_custom_domain = true)"
  type        = string
  default     = ""
}

variable "subdomain" {
  type    = string
  default = "assets"
}

variable "bucket_name" {
  description = "Globally unique name for the origin bucket"
  type        = string
}

variable "github_repo" {
  description = "GitHub repo allowed to deploy, format ORG/REPO"
  type        = string
}

variable "github_branch" {
  type    = string
  default = "main"
}

variable "create_github_oidc_provider" {
  description = "Set false if the account already has the GitHub OIDC provider"
  type        = bool
  default     = true
}

variable "waf_count_mode" {
  description = "true = rules only count (safe rollout). Set false to enforce blocking."
  type        = bool
  default     = true
}

variable "rate_limit" {
  description = "Max requests per IP per 5 minutes before the rate rule triggers"
  type        = number
  default     = 2000
}

variable "price_class" {
  description = "PriceClass_100 | PriceClass_200 (includes India) | PriceClass_All"
  type        = string
  default     = "PriceClass_200"
}

variable "alarm_email" {
  description = "Email for CloudWatch alarm notifications"
  type        = string
}
