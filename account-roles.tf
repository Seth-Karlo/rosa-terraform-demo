data "rhcs_policies" "all_policies" {}

data "rhcs_versions" "all" {}

module "create_account_roles"{
  source  = "terraform-redhat/rosa-sts/aws"
  version = "0.0.14"

  create_account_roles = true

  account_role_prefix      = var.account_role_prefix
  path                     = var.path
  ocm_environment          = var.ocm_environment
  rosa_openshift_version   = regex("^[0-9]+\\.[0-9]+", var.rosa_openshift_version)
  account_role_policies    = data.rhcs_policies.all_policies.account_role_policies
  all_versions             = data.rhcs_versions.all
  operator_role_policies   = data.rhcs_policies.all_policies.operator_role_policies
  tags                     = var.additional_tags

}

