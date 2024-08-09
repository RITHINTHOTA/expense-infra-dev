module "db" {
    source = "../../terraform-aws-securitygroup"
    project_name = var.project_name
    environment = var.environment
    sg_description = "SG FOR DB SECURITY GROUP "
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = var.common_tags
    sg_name = "db"
}

module "backend" {
    source = "../../terraform-aws-securitygroup"
    project_name = var.project_name
    environment = var.environment
    sg_description = "SG FOR BACKEND SECURITY GROUP "
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = var.common_tags
    sg_name = "backend"
}

module "frontend" {
    source = "../../terraform-aws-securitygroup"
    project_name = var.project_name
    environment = var.environment
    sg_description = "SG FOR FRONTEND SECURITY GROUP "
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = var.common_tags
    sg_name = "frontend"
}
module "web_alb" {
    source = "../../terraform-aws-securitygroup"
    project_name = var.project_name
    environment = var.environment
    sg_description = "SG FOR WEB ALB INSTANCES"
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = var.common_tags
    sg_name = "web_alb"
}
module "bastion" {
    source = "../../terraform-aws-securitygroup"
    project_name = var.project_name
    environment = var.environment
    sg_description = "SG FOR BASTION SECURITY GROUP "
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = var.common_tags
    sg_name = "bastion"
}
module "app_alb" {
    source = "../../terraform-aws-securitygroup"
    project_name = var.project_name
    environment = var.environment
    sg_description = "SG FOR APP ALB Instances "
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = var.common_tags
    sg_name = "app_alb"
}
module "vpn" {
    source = "../../terraform-aws-securitygroup"
    project_name = var.project_name
    environment = var.environment
    sg_description = "SG FOR VPN "
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = var.common_tags
    sg_name = "vpn"
    ingress_rules = var.vpn_sg_rules

}
# DB is accepting connections from backend
resource "aws_security_group_rule" "db_backend" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  source_security_group_id =  module.backend.sg_id# source is where you are getting the traffic
  security_group_id = module.db.sg_id
}
# DB is accepting connections from bastion
resource "aws_security_group_rule" "db_bastion" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  source_security_group_id =  module.bastion.sg_id# source is where you are getting the traffic
  security_group_id = module.db.sg_id
}
# DB is accepting connections from vpn
resource "aws_security_group_rule" "db_vpn" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  source_security_group_id =  module.vpn.sg_id# source is where you are getting the traffic
  security_group_id = module.db.sg_id
}
# Backend is accepting connections from frontend
resource "aws_security_group_rule" "backend_app_alb" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  source_security_group_id =  module.app_alb.sg_id# source is where you are getting the traffic
  security_group_id = module.backend.sg_id
}

# Backend is accepting connections from bastion
resource "aws_security_group_rule" "backend_bastion" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  source_security_group_id =  module.bastion.sg_id# source is where you are getting the traffic
  security_group_id = module.backend.sg_id
}

# backend accepting connections from vpn ssh
resource "aws_security_group_rule" "backend_vpn_ssh" { # edhi server ke login avadaniki
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  source_security_group_id =  module.vpn.sg_id # source is where you are getting the traffic
  security_group_id = module.backend.sg_id
}
# backend accepting connections from vpn http
resource "aws_security_group_rule" "backend_vpn_http" { # edhi  manam appudina backend lo trouble shoot cheydaniki use avthundhi like manam *app-dev.rithinexpense.online ane manam browser nucnchi access chesam ala.
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  source_security_group_id =  module.vpn.sg_id# source is where you are getting the traffic
  security_group_id = module.backend.sg_id
}

# load balancer accepting connections from vpn 
resource "aws_security_group_rule" "app_alb_vpn" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  source_security_group_id = module.vpn.sg_id# source is where you are getting the traffic
  security_group_id = module.app_alb.sg_id
}
resource "aws_security_group_rule" "app_alb_bastion" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  source_security_group_id = module.bastion.sg_id# source is where you are getting the traffic
  security_group_id = module.app_alb.sg_id
}
resource "aws_security_group_rule" "app_alb_frontend" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  source_security_group_id = module.frontend.sg_id# source is where you are getting the traffic
  security_group_id = module.app_alb.sg_id
}


resource "aws_security_group_rule" "frontend_bastion" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  source_security_group_id = module.bastion.sg_id# source is where you are getting the traffic
  security_group_id = module.frontend.sg_id
}
resource "aws_security_group_rule" "frontend_vpn" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  source_security_group_id = module.vpn.sg_id# source is where you are getting the traffic
  security_group_id = module.frontend.sg_id
}

resource "aws_security_group_rule" "frontend_web_alb" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  source_security_group_id = module.web_alb.sg_id# source is where you are getting the traffic
  security_group_id = module.frontend.sg_id
}
resource "aws_security_group_rule" "web_alb_public" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks = ["0.0.0.0/0"]# source is where you are getting the traffic
  security_group_id = module.web_alb.sg_id
}
resource "aws_security_group_rule" "web_alb_public_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks = ["0.0.0.0/0"]# source is where you are getting the traffic
  security_group_id = module.web_alb.sg_id
}
# bastion accepting connections from  public
resource "aws_security_group_rule" "bastion_public" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks = ["0.0.0.0/0"]# source is where you are getting the traffic
  security_group_id = module.bastion.sg_id
}

