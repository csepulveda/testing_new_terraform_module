module "aws_elasticache_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name   = "service-one-sg"
  vpc_id = module.vpc.vpc_id

  egress_rules = ["all-all"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 6379
      to_port     = 6379
      protocol    = "tcp"
      cidr_blocks = join(",", concat(module.vpc.elasticache_subnets_cidr_blocks, module.vpc.private_subnets_cidr_blocks))
    },
  ]
}

resource "aws_elasticache_subnet_group" "redis-node" {
  name       = "redis-cluster-cache-subnet"
  subnet_ids = module.vpc.elasticache_subnets
}

resource "aws_elasticache_cluster" "redis-node" {
  cluster_id           = "redis-cluster"
  engine               = "redis"
  node_type            = "cache.t4g.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis6.x"
  engine_version       = "6.2"
  port                 = 6379

  security_group_ids = [module.aws_elasticache_security_group.security_group_id]
  subnet_group_name  = aws_elasticache_subnet_group.redis-node.name
}

