resource "aws_launch_configuration" "web" {
  name_prefix                 = "web-lc"
  image_id                    = "${var.web_ami}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.instance_key}"
  security_groups             = ["${aws_security_group.allow_http.id}"]
  associate_public_ip_address = false

  user_data = <<USER_DATA
    #!/bin/bash
    yum update
    yum -y install httpd
    echo "Hello World $(curl http://169.254.169.254/latest/meta-data/hostname)" > /var/www/html/index.html
    chkconfig httpd on
    service httpd start
  USER_DATA

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web" {
  name = "${aws_launch_configuration.web.name}-asg"

  min_size         = "${var.aws_autoscaling_group_capacity["min"]}"
  desired_capacity = "${var.aws_autoscaling_group_capacity["desired"]}"
  max_size         = "${var.aws_autoscaling_group_capacity["max_size"]}"

  health_check_type = "ELB"
  load_balancers    = ["${aws_elb.web_elb.id}"]

  launch_configuration = "${aws_launch_configuration.web.name}"

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances",
  ]

  metrics_granularity = "1Minute"

  vpc_zone_identifier = ["${aws_subnet.private.*.id}"]

  # Required to redeploy without an outage.
  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "web"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "web_policy_up" {
  name                   = "web_policy_up"
  scaling_adjustment     = "${var.aws_autoscaling_policy_up["scaling_adjustment"]}"
  adjustment_type        = "${var.aws_autoscaling_policy_up["adjustment_type"]}"
  cooldown               = "${var.aws_autoscaling_policy_up["cooldown"]}"
  autoscaling_group_name = "${aws_autoscaling_group.web.name}"
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_up" {
  alarm_name          = "web_cpu_alarm_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "60"

  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.web.name}"
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions     = ["${aws_autoscaling_policy.web_policy_up.arn}"]
}

resource "aws_autoscaling_policy" "web_policy_down" {
  name                   = "web_policy_down"
  scaling_adjustment     = "${var.aws_autoscaling_policy_down["scaling_adjustment"]}"
  adjustment_type        = "${var.aws_autoscaling_policy_down["adjustment_type"]}"
  cooldown               = "${var.aws_autoscaling_policy_down["cooldown"]}"
  autoscaling_group_name = "${aws_autoscaling_group.web.name}"
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_down" {
  alarm_name          = "web_cpu_alarm_down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "10"

  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.web.name}"
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions     = ["${aws_autoscaling_policy.web_policy_down.arn}"]
}
