output "site_url" {
  value = var.use_custom_domain ? "https://${local.fqdn}" : "https://${aws_cloudfront_distribution.this.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "Save as GitHub variable CF_DISTRIBUTION_ID"
  value       = aws_cloudfront_distribution.this.id
}

output "s3_bucket" {
  description = "Save as GitHub variable S3_BUCKET"
  value       = aws_s3_bucket.origin.id
}

output "github_role_arn" {
  description = "Save as GitHub variable AWS_ROLE_ARN"
  value       = aws_iam_role.github_deploy.arn
}

output "waf_log_group" {
  value = aws_cloudwatch_log_group.waf.name
}
