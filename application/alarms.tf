module "alb_alarms" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "~> 5.3"

  for_each = {
    "5xx" = {
      metric_name = "HTTPCode_Target_5XX_Count"
      threshold   = 10
      description = "ALB target 5XX error rate has exceeded 10 in 5 minutes"
    }
    "4xx" = {
      metric_name = "HTTPCode_Target_4XX_Count"
      threshold   = 50
      description = "ALB target 4XX error rate has exceeded 50 in 5 minutes"
    }
  }

  alarm_name          = "${var.company_name}-${var.environment}-alb-target-${each.key}-errors"
  alarm_description   = each.value.description
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = each.value.threshold
  period              = 300
  unit                = "Count"

  namespace   = "AWS/ApplicationELB"
  metric_name = each.value.metric_name
  statistic   = "Sum"

  dimensions = {
    TargetGroup  = data.terraform_remote_state.network.outputs.alb_target_group_arn_suffix
    LoadBalancer = data.terraform_remote_state.network.outputs.alb_arn_suffix
  }

  tags = {
    Environment = var.environment
    Project     = var.company_name
  }
}
