# CloudFront and WAF metrics live in us-east-1, so alarms/dashboard/SNS do too.
resource "aws_sns_topic" "alerts" {
  provider = aws.us_east_1
  name     = "${var.bucket_name}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  provider  = aws.us_east_1
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

resource "aws_cloudwatch_metric_alarm" "cf_5xx" {
  provider            = aws.us_east_1
  alarm_name          = "${var.bucket_name}-5xx-rate-high"
  namespace           = "AWS/CloudFront"
  metric_name         = "5xxErrorRate"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 5
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  dimensions = {
    DistributionId = aws_cloudfront_distribution.this.id
    Region         = "Global"
  }
}

resource "aws_cloudwatch_metric_alarm" "waf_blocked" {
  provider            = aws.us_east_1
  alarm_name          = "${var.bucket_name}-waf-blocked-spike"
  namespace           = "AWS/WAFV2"
  metric_name         = "BlockedRequests"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 500
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  dimensions = {
    WebACL = aws_wafv2_web_acl.this.name
    Rule   = "ALL"
    Region = "Global"
  }
}

resource "aws_cloudwatch_dashboard" "cdn" {
  provider       = aws.us_east_1
  dashboard_name = "${var.bucket_name}-cdn"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric", x = 0, y = 0, width = 12, height = 6
        properties = {
          title   = "Requests"
          region  = "us-east-1"
          stat    = "Sum"
          period  = 300
          metrics = [["AWS/CloudFront", "Requests", "DistributionId", aws_cloudfront_distribution.this.id, "Region", "Global"]]
        }
      },
      {
        type = "metric", x = 12, y = 0, width = 12, height = 6
        properties = {
          title  = "Error rates (%)"
          region = "us-east-1"
          stat   = "Average"
          period = 300
          metrics = [
            ["AWS/CloudFront", "4xxErrorRate", "DistributionId", aws_cloudfront_distribution.this.id, "Region", "Global"],
            ["AWS/CloudFront", "5xxErrorRate", "DistributionId", aws_cloudfront_distribution.this.id, "Region", "Global"]
          ]
        }
      },
      {
        type = "metric", x = 0, y = 6, width = 12, height = 6
        properties = {
          title   = "Bytes downloaded"
          region  = "us-east-1"
          stat    = "Sum"
          period  = 300
          metrics = [["AWS/CloudFront", "BytesDownloaded", "DistributionId", aws_cloudfront_distribution.this.id, "Region", "Global"]]
        }
      },
      {
        type = "metric", x = 12, y = 6, width = 12, height = 6
        properties = {
          title  = "WAF allowed vs blocked"
          region = "us-east-1"
          stat   = "Sum"
          period = 300
          metrics = [
            ["AWS/WAFV2", "AllowedRequests", "WebACL", aws_wafv2_web_acl.this.name, "Rule", "ALL", "Region", "Global"],
            ["AWS/WAFV2", "BlockedRequests", "WebACL", aws_wafv2_web_acl.this.name, "Rule", "ALL", "Region", "Global"]
          ]
        }
      }
    ]
  })
}
