resource "aws_ecs_service" "my_first_service" {
  name            = "my-first-service"                             # Naming our first service
  cluster         = "${aws_ecs_cluster.my_cluster.id}"             # Referencing our created Cluster
  task_definition = "${aws_ecs_task_definition.my_first_task.arn}" # Referencing the task our service will spin up
  launch_type     = "FARGATE"
  desired_count   = 2 # Setting the number of containers we want deployed to 3
  # deployment_controller {
  #   type = "CODE_DEPLOY"
  }
  load_balancer {
    target_group_arn = "${aws_lb_target_group.target_group.arn}" # Referencing our target group
    container_name   = "${aws_ecs_task_definition.my_first_task.family}"
    container_port   = 80 # Specifying the container port
  }
  
  network_configuration {
    subnets          = ["subnet-0c0dbee3b7b03e4e2", "subnet-0fd7ec9b1f3cdd68d"]
    assign_public_ip = true # Providing our containers with public IPs
    security_groups   = [aws_security_group.service_security_group.id]
  }
}

resource "aws_security_group" "service_security_group" {
  name = "kk-ecs-test"
  vpc_id      = "vpc-06a0bfef01b9d0e7b"
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # Only allowing traffic in from the load balancer security group
    security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
  }

  egress {
    from_port   = 0 # Allowing any incoming port
    to_port     = 0 # Allowing any outgoing port
    protocol    = "-1" # Allowing any outgoing protocol 
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic out to all IP addresses
  }
}


# added


resource "aws_alb_target_group" "ecs_app_target_group" {
  name        = "blue-green"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "vpc-06a0bfef01b9d0e7b"
  target_type = "ip"

  health_check {
    path                = "/actuator/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = "60"
    timeout             = "30"
    unhealthy_threshold = "3"
    healthy_threshold   = "3"
  }

  tags = {
    Name = "bluegrean-TG"
  }
}

resource "aws_alb_listener_rule" "ecs_alb_listener_rule" {
  listener_arn = "arn:aws:elasticloadbalancing:us-west-2:944706592399:listener/app/test-lb-tf/19a16f8a841d2042/26b5b6413e55e2de"
  
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.ecs_app_target_group.arn
  }

  condition {
    path_pattern {
      values = ["test/plain"]
    }
  }
}

# # resource "aws_cloudwatch_log_group" "springbootapp_log_group" {
# #   name = "${var.ecs_service_name}-LogGroup"
# # }

