module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  name               = "services"
  container_insights = true
  create_ecs         = true
  capacity_providers = ["FARGATE"]

}