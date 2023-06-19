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

#variable "installer_role_arn" {
#  type = string
#}
