data "rhcs_policies" "all_policies" {}

data "rhcs_versions" "all" {}

module "create_account_roles"{
  source  = "terraform-redhat/rosa-sts/aws"
  version = "0.0.12"

  create_account_roles = true

  account_role_prefix      = var.account_role_prefix
  path                     = var.path
  ocm_environment          = var.ocm_environment
  rosa_openshift_version   = var.rosa_openshift_version
  account_role_policies    = var.account_role_policies
  all_versions             = var.all_versions
  operator_role_policies   = var.operator_role_policies
  tags                     = var.additional_tags

}

# Generates the OIDC config resources' names
resource "rhcs_rosa_oidc_config_input" "oidc_input" {
  count = var.managed ? 0 : 1
  region = var.aws_region
}

# Create the OIDC config resources on AWS
module "oidc_config_input_resources" {
  source  = "terraform-redhat/rosa-sts/aws"
  version = "0.0.14"

  create_oidc_config_resources = true

  bucket_name             = one(rhcs_rosa_oidc_config_input.oidc_input[*].bucket_name)
  discovery_doc           = one(rhcs_rosa_oidc_config_input.oidc_input[*].discovery_doc)
  jwks                    = one(rhcs_rosa_oidc_config_input.oidc_input[*].jwks)
  private_key             = one(rhcs_rosa_oidc_config_input.oidc_input[*].private_key)
  private_key_file_name   = one(rhcs_rosa_oidc_config_input.oidc_input[*].private_key_file_name)
  private_key_secret_name = one(rhcs_rosa_oidc_config_input.oidc_input[*].private_key_secret_name)
}

resource "rhcs_rosa_oidc_config" "oidc_config" {
  managed            = true
  secret_arn         = one(module.oidc_config_input_resources[*].secret_arn)
  issuer_url         = one(rhcs_rosa_oidc_config_input.oidc_input[*].issuer_url)
  installer_role_arn = var.installer_role_arn
}

data "rhcs_rosa_operator_roles" "operator_roles" {
  operator_role_prefix = var.operator_role_prefix
  account_role_prefix  = var.account_role_prefix
}

module "operator_roles_and_oidc_provider" {
  source  = "terraform-redhat/rosa-sts/aws"
  version = "0.0.14"

  create_operator_roles = true
  create_oidc_provider  = true

  cluster_id                  = ""
  rh_oidc_provider_thumbprint = rhcs_rosa_oidc_config.oidc_config.thumbprint
  rh_oidc_provider_url        = rhcs_rosa_oidc_config.oidc_config.oidc_endpoint_url
  operator_roles_properties   = data.rhcs_rosa_operator_roles.operator_roles.operator_iam_roles
  tags                        = var.additional_tags
  path                        = var.path
}
