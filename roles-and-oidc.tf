# Gather all policies from OCM. If this fails, double check token
data "ocm_policies" "all_policies" {}

# Get AWS Caller identity
data "aws_caller_identity" "current" {}

# Create the main four account roles for ROSA install
module "create_account_roles" {
  source  = "terraform-redhat/rosa-sts/aws"
  version = ">=0.0.5"

  create_operator_roles = false
  create_oidc_provider  = false
  create_account_roles  = true

  account_role_prefix    = var.account_role_prefix
  ocm_environment        = var.ocm_environment
  rosa_openshift_version = var.openshift_version
  account_role_policies  = data.ocm_policies.all_policies.account_role_policies
  operator_role_policies = data.ocm_policies.all_policies.operator_role_policies
  # Add permissions boundary here
}

# Generate config for the OIDC provider that will be uploaded to the bucket
resource "ocm_rosa_oidc_config_input" "oidc_input" {
  region = var.region_name
}

# Generate the bucket that is the backend for the OIDC provider
module "oidc_config_input_resources" {
  source  = "terraform-redhat/rosa-sts/aws"
  version = "0.0.5"

  create_oidc_config_resources = true

  bucket_name             = ocm_rosa_oidc_config_input.oidc_input.bucket_name
  discovery_doc           = ocm_rosa_oidc_config_input.oidc_input.discovery_doc
  jwks                    = ocm_rosa_oidc_config_input.oidc_input.jwks
  private_key             = ocm_rosa_oidc_config_input.oidc_input.private_key
  private_key_file_name   = ocm_rosa_oidc_config_input.oidc_input.private_key_file_name
  private_key_secret_name = ocm_rosa_oidc_config_input.oidc_input.private_key_secret_name
}

# Create the oidc provier config
resource "ocm_rosa_oidc_config" "oidc_config" {
  managed            = false
  secret_arn         = module.oidc_config_input_resources.secret_arn
  issuer_url         = ocm_rosa_oidc_config_input.oidc_input.issuer_url
  installer_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.account_role_prefix}-Installer-Role"
  depends_on         = [module.create_account_roles]
}

# Create a CloudFront Distribution for the OIDC provider so the s3 bucket doesn't need to be public

resource "aws_cloudfront_origin_access_identity" "cloudfront_origin_access_identity" {
  comment = "OAI-${ocm_rosa_oidc_config_input.oidc_input.bucket_name}"
}

resource "aws_cloudfront_distribution" "oidc_s3_distribution" {
  origin {
    domain_name              = ocm_rosa_oidc_config.oidc_config.oidc_endpoint_url
    origin_id                = ocm_rosa_oidc_config.oidc_config.oidc_endpoint_url
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cloudfront_origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  comment             = "${var.cluster_name}"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = ocm_rosa_oidc_config.oidc_config.oidc_endpoint_url
    viewer_protocol_policy = "https-only"
    cache_policy_id     = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
  }

  price_class = "PriceClass_All"

  tags = {
    Name = "${var.cluster_name}"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# Generate new thumbprint based on CloudFront URL
# This is a hack until we can add CloudFront options to the module
data "external" "thumbprint" {
  program = ["./thumbprint.sh", aws_cloudfront_distribution.oidc_s3_distribution.domain_name]
}

# Update bucket access policy
# This is a hack until we can add CloudFront options to the module
# This _will_ cause a drift as the module will first apply the public access one then this will lock it down

# Get information on the operator roles
data "ocm_rosa_operator_roles" "operator_roles" {
  operator_role_prefix = var.operator_role_prefix
  account_role_prefix  = var.account_role_prefix
}

# Generate the operator roles and OIDC provider. The operator roles rely on the OIDC provider and the provider relies on the bucket created above
module "operator_roles_and_oidc_provider" {
  source  = "terraform-redhat/rosa-sts/aws"
  version = ">=0.0.5"

  create_operator_roles = true
  create_oidc_provider  = true

  cluster_id                  = var.cluster_name
  rh_oidc_provider_thumbprint = data.external.thumbprint.result.thumbprint
  rh_oidc_provider_url        = aws_cloudfront_distribution.oidc_s3_distribution.domain_name
  operator_roles_properties   = data.ocm_rosa_operator_roles.operator_roles.operator_iam_roles
  depends_on                  = [ocm_rosa_oidc_config.oidc_config]
}
