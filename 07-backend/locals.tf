locals {
    private_subnet_id = element(split(",", data.aws_ssm_parameter.private_subnet_ids.value),0) # ee list nundi first element ravali kabatee manam element function use chestunam.
}