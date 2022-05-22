module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  name               = "services"
  container_insights = true
  create_ecs         = true
  capacity_providers = ["FARGATE"]

}

##service one

module "service_one_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name   = "service-one-sg"
  vpc_id = module.vpc.vpc_id

  egress_rules = ["all-all"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = join(",", concat(module.vpc.public_subnets_cidr_blocks, module.vpc.private_subnets_cidr_blocks))
    },
  ]
}

module "public_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name   = "public-loadbalancer-sg"
  vpc_id = module.vpc.vpc_id

  egress_rules = ["all-all"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}

resource "aws_lb" "service-one" {
  name               = "service-one-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.service_one_security_group.security_group_id, module.public_security_group.security_group_id]
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = false
}


resource "aws_lb_target_group" "service-one" {
  name        = "service-one-alb"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id

  deregistration_delay = 30
}

resource "aws_lb_listener" "service-one" {
  load_balancer_arn = aws_lb.service-one.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service-one.arn
  }
}

resource "aws_ecs_task_definition" "service-one" {
  family       = "service"
  network_mode = "awsvpc"
  cpu          = 256
  memory       = 512

  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([
    {
      name      = "container-one"
      image     = "gcr.io/google-containers/echoserver:1.10"
      cpu       = 128
      memory    = 256
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "service-one" {
  name            = "service-one"
  cluster         = module.ecs.ecs_cluster_id
  task_definition = aws_ecs_task_definition.service-one.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.private_subnets
    assign_public_ip = false
    security_groups  = [module.service_one_security_group.security_group_id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.service-one.arn
    container_name   = "container-one"
    container_port   = 8080
  }

}
