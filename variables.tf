variable "token" {
  type      = string
  sensitive = true
}

variable "url" {
  type    = string
  default = "https://api.openshift.com"
}

variable "operator_role_prefix" {
  type    = string
  default = ""
}

variable "account_role_prefix" {
  type    = string
  default = ""
}

variable "region_name" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "ocm_environment" {
  type    = string
  default = "production"
}

variable "openshift_version" {
  default = "4.12"
}

variable "availability_zones" {
  type    = list(any)
  default = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "aws_subnet_ids" {
  type = list(any)
}

variable "replicas" {
  type    = number
  default = 3
}

variable "machine_cidr" {
  type = string
}
