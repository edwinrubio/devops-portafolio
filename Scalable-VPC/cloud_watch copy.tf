resource "aws_cloudwatch_metric_alarm" "asg_state_change_alarm" {
  alarm_name          = "ASGStateChangeAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/AutoScaling"
  period              = 60
  statistic           = "SampleCount"
  threshold           = 80
  alarm_description   = "ASG state change detected"
  alarm_actions       = [aws_sns_topic.autoscaling_update.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.my-autoescaling-group.name
  }
}

resource "aws_sns_topic" "autoscaling_update" {
  name = "autoscaling_update"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.autoscaling_update.arn
  protocol  = "email"
  endpoint  = "correo_electronico@example.com"
}