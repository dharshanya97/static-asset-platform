locals {
  managed_rule_groups = [
    { name = "AWSManagedRulesCommonRuleSet", priority = 1 },
    { name = "AWSManagedRulesKnownBadInputsRuleSet", priority = 2 },
    { name = "AWSManagedRulesAmazonIpReputationList", priority = 3 },
    # Bot Control costs extra. Uncomment to enable:
    # { name = "AWSManagedRulesBotControlRuleSet", priority = 4 },
  ]
}

resource "aws_wafv2_web_acl" "this" {
  provider    = aws.us_east_1
  name        = "${var.bucket_name}-web-acl"
  description = "WAF for static asset CDN"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  dynamic "rule" {
    for_each = local.managed_rule_groups
    content {
      name     = rule.value.name
      priority = rule.value.priority

      override_action {
        dynamic "count" {
          for_each = var.waf_count_mode ? [1] : []
          content {}
        }
        dynamic "none" {
          for_each = var.waf_count_mode ? [] : [1]
          content {}
        }
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value.name
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value.name
        sampled_requests_enabled   = true
      }
    }
  }

  rule {
    name     = "RateLimitPerIP"
    priority = 10

    action {
      dynamic "count" {
        for_each = var.waf_count_mode ? [1] : []
        content {}
      }
      dynamic "block" {
        for_each = var.waf_count_mode ? [] : [1]
        content {}
      }
    }

    statement {
      rate_based_statement {
        limit              = var.rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitPerIP"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.bucket_name}-web-acl"
    sampled_requests_enabled   = true
  }
}

# ---------- WAF logging ----------
resource "aws_cloudwatch_log_group" "waf" {
  provider          = aws.us_east_1
  name              = "aws-waf-logs-${var.bucket_name}" # name MUST start with aws-waf-logs-
  retention_in_days = 30
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "waf_logs" {
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.waf.arn}:*"]
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "waf" {
  provider        = aws.us_east_1
  policy_name     = "aws-waf-logs-${var.bucket_name}"
  policy_document = data.aws_iam_policy_document.waf_logs.json
}

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  provider                = aws.us_east_1
  log_destination_configs = [aws_cloudwatch_log_group.waf.arn]
  resource_arn            = aws_wafv2_web_acl.this.arn
  depends_on              = [aws_cloudwatch_log_resource_policy.waf]
}
