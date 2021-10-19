provider "aws" {
  alias = "dnsProvider"
}

###################################################################
# SECURITY GROUPS
###################################################################

#
# Create the single security group to manage traffic to RDS.
#
resource "aws_security_group" "rds_sg" {
  name   = "${var.environment}-${var.app_name}-rds-sg"
  vpc_id = var.vpc_id

  tags = {
    Application = var.app_name
    Billing     = var.environment
    Environment = var.environment
    Name        = "${var.environment}-${var.app_name}-rds-sg"
    Terraform   = true
  }
}

#
# Create all of the rules for this security group.
#
resource "aws_security_group_rule" "rds_egress_all" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.rds_sg.id
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rds_ingress" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.rds_sg.id
  self              = true
  to_port           = 0
  type              = "ingress"
}

resource "aws_security_group_rule" "rds_ingress_mysql" {
  cidr_blocks       = var.ingress_cidr_blocks
  from_port         = 3306
  protocol          = "-1"
  security_group_id = aws_security_group.rds_sg.id
  to_port           = 3306
  type              = "ingress"
}

resource "aws_security_group_rule" "rds_ingress_mysql_from_home" {
  cidr_blocks       = ["66.182.197.254/32"]
  from_port         = 3306
  protocol          = "-1"
  security_group_id = aws_security_group.rds_sg.id
  to_port           = 3306
  type              = "ingress"
}

resource "aws_db_subnet_group" "default" {
  name       = "private_data_subnets" # cannot change this name without creating a new aurora cluster
  subnet_ids = concat(var.private_subnets, var.public_subnets)

  tags = {
    Application = var.app_name
    Billing     = "${var.environment}-${var.app_name}"
    Environment = var.environment
    Name        = "${var.environment}-${var.app_name}-aurora-cluster-subnet-group"
    Terraform   = true
  }
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  #apply_immediately    = true
  cluster_identifier   = aws_rds_cluster.cluster.id
  count                = var.replica_count
  db_subnet_group_name = aws_db_subnet_group.default.name
  engine               = var.engine
  identifier_prefix    = "${var.environment}-${var.app_name}-db"
  instance_class       = var.db_instance_class
  publicly_accessible  = true

  tags = {
    Application = var.app_name
    Billing     = "${var.environment}-${var.app_name}"
    Environment = var.environment
    Name        = "${var.environment}-${var.app_name}-db${count.index}"
    Terraform   = true
  }
}

#
# Obtain the master username and password from AWS Secrets Manager.
#
data "aws_secretsmanager_secret" "aurora_master_pwd" {
  name = "${var.environment}-${var.app_name}-aurora-pwd"
}

data "aws_secretsmanager_secret_version" "aurora_master_pwd" {
  secret_id = data.aws_secretsmanager_secret.aurora_master_pwd.id
}

data "aws_secretsmanager_secret" "aurora_master_user" {
  name = "${var.environment}-${var.app_name}-aurora-user"
}

data "aws_secretsmanager_secret_version" "aurora_master_user" {
  secret_id = data.aws_secretsmanager_secret.aurora_master_user.id
}

resource "aws_rds_cluster" "cluster" {
  availability_zones     = var.availability_zones
  cluster_identifier     = "${var.environment}-${var.app_name}-aurora"
  db_subnet_group_name   = aws_db_subnet_group.default.name
  deletion_protection    = true
  engine                 = var.engine
  master_password        = data.aws_secretsmanager_secret_version.aurora_master_pwd.secret_string
  master_username        = data.aws_secretsmanager_secret_version.aurora_master_user.secret_string
  port                   = "3306"
  skip_final_snapshot    = true
  vpc_security_group_ids = concat(list(aws_security_group.rds_sg.id), var.additional_security_groups)

  tags = {
    Application = var.app_name
    Billing     = "${var.environment}-${var.app_name}"
    Environment = var.environment
    Name        = "${var.environment}-${var.app_name}-aurora-cluster"
    Terraform   = true
  }
}

###################################################################
# ROUTE 53: CREATE ENTRIES POINTING TO AURORA ENDPOINTS.
###################################################################

resource "aws_route53_record" "dns_rds_writer_a" {
  name     = "${var.environment}.db"
  provider = aws.dnsProvider
  type     = "A"
  zone_id  = var.zone_id

  alias {
    evaluate_target_health = false
    name                   = aws_rds_cluster.cluster.endpoint
    zone_id                = aws_rds_cluster.cluster.hosted_zone_id
  }
}

resource "aws_route53_record" "dns_rds_writer_aaaa" {
  name     = "${var.environment}.db"
  provider = aws.dnsProvider
  type     = "AAAA"
  zone_id  = var.zone_id

  alias {
    evaluate_target_health = false
    name                   = aws_rds_cluster.cluster.endpoint
    zone_id                = aws_rds_cluster.cluster.hosted_zone_id
  }
}

resource "aws_route53_record" "dns_rds_readonly_a" {
  name     = "${var.environment}.ro.db"
  provider = aws.dnsProvider
  type     = "A"
  zone_id  = var.zone_id

  alias {
    evaluate_target_health = false
    name                   = aws_rds_cluster.cluster.reader_endpoint
    zone_id                = aws_rds_cluster.cluster.hosted_zone_id
  }
}

resource "aws_route53_record" "dns_rds_readonly_aaaa" {
  name     = "${var.environment}.ro.db"
  provider = aws.dnsProvider
  type     = "AAAA"
  zone_id  = var.zone_id

  alias {
    evaluate_target_health = false
    name                   = aws_rds_cluster.cluster.reader_endpoint
    zone_id                = aws_rds_cluster.cluster.hosted_zone_id
  }
}
