resource "aws_cloudwatch_metric_alarm" "asg_state_change_alarm_app" {
  alarm_name          = "ASGStateChangeAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/AutoScaling"
  period              = 60
  statistic           = "SampleCount"
  threshold           = 80
  alarm_description   = "ASG state change detected"
  alarm_actions       = [aws_sns_topic.autoscaling_update_app.arn]

  dimensions = {
    AutoScalingGroupName = aws_security_group.app_security_group.name
  }
}

resource "aws_sns_topic" "autoscaling_update_app" {
  name = "autoscaling_update"
}

resource "aws_sns_topic_subscription" "email_subscription_app" {
  topic_arn = aws_sns_topic.autoscaling_update_app.arn
  protocol  = "email"
  endpoint  = "correo_electronico@example.com"
}

resource "aws_cloudwatch_log_group" "vpc_bastion_group_log" {
  name = "flow-bastion-logs"
  retention_in_days = 7  # Cambia el período de retención según tus requisitos
}

resource "aws_flow_log" "bastion_flow_log" {
  iam_role_arn    = aws_iam_role.logs_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_bastion_group_log.arn
  traffic_type    = "ALL"
  vpc_id          = module.vpc-bastion.vpc_id
}

resource "aws_flow_log" "app_flow_log" {
  iam_role_arn    = aws_iam_role.logs_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_app_group_log.arn
  traffic_type    = "ALL"
  vpc_id          = module.vpc-app.vpc_id
}



resource "aws_cloudwatch_log_group" "vpc_app_group_log" {
  name = "flow-app-logs"

  retention_in_days = 7  # Cambia el período de retención según tus requisitos
}


# permission log group

data "aws_iam_policy_document" "logs_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "logs_role" {
  name               = "logs_role"
  assume_role_policy = data.aws_iam_policy_document.logs_role.json
}

data "aws_iam_policy_document" "iam_policy_logs" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "role_policy" {
  name   = "role_policy"
  role   = aws_iam_role.logs_role.id
  policy = data.aws_iam_policy_document.iam_policy_logs.json
}

