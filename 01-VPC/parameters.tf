resource "aws_ssm_parameter" "vpc_id" {
  name  = "/${var.project_name}/${var.environment}/vpc_id"
  type  = "String"
  value = module.vpc.vpc_id
}
resource "aws_ssm_parameter" "public_subnet_ids" {
  name  = "/${var.project_name}/${var.environment}/public_subnet_ids"
  type  = "StringList"
  value = join ( ",",module.vpc.Public_subnet_ids) # converting list to  string list
}
#["id", "id2"]----> terraform format of list
# id1,id2 ---> AWS SSM format
# so manam list ne terraform format nunchi ssm format loki change cheyali. edhi manam JOIN use cheyachu
resource "aws_ssm_parameter" "Private_subnet_ids" {
  name  = "/${var.project_name}/${var.environment}/private_subnet_ids"
  type  = "StringList"
  value = join ( "," ,module.vpc.Private_subnet_ids) # converting list to  string list
}

resource "aws_ssm_parameter" "db_subnet_group_name" {
  name  = "/${var.project_name}/${var.environment}/db_subnet_group_name"
  type  = "String"
  value = module.vpc.database_subnet_group_name
}


