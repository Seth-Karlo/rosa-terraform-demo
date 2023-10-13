# Generates the OIDC config resources' names
resource "rhcs_rosa_oidc_config_input" "oidc_input" {
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
