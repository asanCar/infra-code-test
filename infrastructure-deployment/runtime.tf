resource "aws_launch_template" "my_service" {
  name_prefix          = var.app_name
  image_id             = data.aws_ami.my_service.id
  instance_type        = var.instance_type
  security_group_names = [aws_security_group.my_service_sg.name]
}

resource "aws_autoscaling_group" "my_service" {
  desired_capacity = 2
  max_size         = 6
  min_size         = 2

  launch_template {
    id      = aws_launch_template.my_service.id
    version = aws_launch_template.my_service.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      auto_rollback          = true
    }
  }

  vpc_zone_identifier = [for subnet in aws_subnet.private : subnet.id]
  target_group_arns   = [aws_lb_target_group.my_service.arn]
}
