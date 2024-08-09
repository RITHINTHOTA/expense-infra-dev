variable "project_name" {
    default = "expense"
}

variable "environment" {
    default = "dev"
}

variable "common_tags" {
    default = {
        Project = "expense"
        Environment = "dev"
        Terraform = "true"
        component = "backend"
    }
}
variable "zone_name" {
    default = "rithinexpense.online"
}
variable "zone_id" {
    default = "Z03895071TTSJ7NLAVMXE"
}