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
}

variable "account_role_prefix" {
  type    = string
}

variable "region_name" {
  type = string
  default = "eu-west-2"
}

variable "cluster_name" {
  type = string
}

variable "ocm_environment" {
  type    = string
  default = "production"
}

variable "openshift_version" {
  default = "4.12.20"
}

variable "availability_zones" {
  type    = list(any)
  default = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
}

variable "replicas" {
  type    = number
  default = 3
}

variable "compute_machine_type" {
  type = string
  default = "m5.xlarge"
}
