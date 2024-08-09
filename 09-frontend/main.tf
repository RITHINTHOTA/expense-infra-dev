module "frontend" {
  source  = "terraform-aws-modules/ec2-instance/aws"
name = "${var.project_name}-${var.environment}-${var.common_tags. component}"

  instance_type          = "t3.micro"
  vpc_security_group_ids = [data.aws_ssm_parameter.frontend_sg_id.value]
  # convert stringlist to list and get first element
  subnet_id  = local.public_subnet_id
  ami = data.aws_ami.ami_info.id
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-${var.common_tags. component}"
    }
  )
}


resource "null_resource" "frontend" { #####11#####
    triggers = {
        instance_id = module.frontend.id # this will be triggered everytime instance is created
    }
    connection {
        type = "ssh"  # manam ee ssh access only vpn ke matrame echam kabatti. vpn unte matrame ee frontend r backends work avthundhi
        user = "ec2-user"
        password = "DevOps321"
        host = module.frontend.private_ip
    }
    provisioner "file" { #edhi mana local lo unde files ne tesukuveli server lo pedutundhi
        source = "${var.common_tags.component}.sh"
        destination = "/tmp/${var.common_tags.component}.sh"
    }
    provisioner "remote-exec" {
        inline = [
            "chmod +x /tmp/${var.common_tags.component}.sh",
            "sudo sh /tmp/${var.common_tags.component}.sh ${var.common_tags.component} ${var.environment}"
        ]
    }
}

resource "aws_ec2_instance_state" "frontend" {
  instance_id = module.frontend.id
  state       = "stopped"
  # stop the server only when null resource provising is completed
  depends_on = [null_resource.frontend]
}
resource "aws_ami_from_instance" "frontend" {
  name               = "${var.project_name}-${var.environment}-${var.common_tags. component}"
  source_instance_id = module.frontend.id
  depends_on = [aws_ec2_instance_state.frontend]
}

resource "null_resource" "frontend_delete" { #####11#####
    triggers = {
        instance_id = module.frontend.id # this will be triggered everytime instance is created
    }
    provisioner "local-exec" { # local-exec nduku ante aws comand line lo chestunam ee termination. adhi mana local lo undhi kabatte.
      command = "aws ec2 terminate-instances --instance-ids ${module.frontend.id}"        
    }
    depends_on = [aws_ami_from_instance.frontend]
}
resource "aws_lb_target_group" "frontend" {
  name     = "${var.project_name}-${var.environment}-${var.common_tags. component}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_ssm_parameter.vpc_id.value
  health_check {
    path = "/"
    port = 80
    protocol = "HTTP"
    healthy_threshold = 2
    unhealthy_threshold = 2
    matcher = "200"
  }
}
  resource "aws_launch_template" "frontend" {
  name = "${var.project_name}-${var.environment}-${var.common_tags. component}"

  image_id = aws_ami_from_instance.frontend.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type = "t3.micro"
  update_default_version = true #sets the latest version to default
  vpc_security_group_ids = [data.aws_ssm_parameter.frontend_sg_id.value]

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      var.common_tags,
      {
      Name = "${var.project_name}-${var.environment}-${var.common_tags. component}"
      }
    )
  }
}
resource "aws_autoscaling_group" "frontend" {
  name                      = "${var.project_name}-${var.environment}-${var.common_tags. component}"
  max_size                  = 5
  min_size                  = 1
  health_check_grace_period = 60
  health_check_type         = "ELB"
  desired_capacity          = 1
  target_group_arns = [aws_lb_target_group.frontend.arn]
  launch_template {
    id = aws_launch_template.frontend.id
    version = "$Latest"
  }
  vpc_zone_identifier = split(",", data.aws_ssm_parameter.public_subnet_ids.value)
  instance_refresh { # appudu aithe kotha launch template create avthundo. appudu manam autoscaling ne refresh cheyali that means old instances ne delete chesi kotha instances ne create cheyali
    strategy = "Rolling" # old dhi poyi new danini tesukuntundhi
    preferences {
      min_healthy_percentage = 50
    }
    triggers = ["launch_template"] # launch template ayina tharavate edhi trigger kavali
    }
  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-${var.common_tags. component}"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }

  tag {
    key                 = "lorem"
    value               = "ipsum"
    propagate_at_launch = false
  }
}
resource "aws_autoscaling_policy" "frontend" {
  name                   = "${var.project_name}-${var.environment}-${var.common_tags. component}"
  policy_type = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.frontend.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 10.0
  }
}

resource "aws_lb_listener_rule" "frontend" {
  listener_arn = data.aws_ssm_parameter.web_alb_listener_arn_https.value
  priority     = 100  # less number wil be first validated

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  condition {
    host_header { #host path ---frontend.rithinexpense.online context path ----- rithin.expense.online/frontend
      values = ["web-${var.environment}.${var.zone_name}"]
    }
  }
}
