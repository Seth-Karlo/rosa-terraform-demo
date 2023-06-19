locals {
  sts_roles = {
    role_arn         = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.account_role_prefix}-Installer-Role",
    support_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.account_role_prefix}-Support-Role",
    instance_iam_roles = {
      master_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.account_role_prefix}-ControlPlane-Role",
      worker_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.account_role_prefix}-Worker-Role"
    },
    operator_role_prefix = var.operator_role_prefix,
    #oidc_config_id       = ocm_rosa_oidc_config.oidc_config.id
    oidc_endpoint_url = aws_cloudfront_distribution.oidc_s3_distribution.domain_name
    oidc_private_key_secret_arn = module.oidc_config_input_resources.secret_arn
  }
}

resource "ocm_cluster_rosa_classic" "rosa_sts_cluster" {
  name               = var.cluster_name
  cloud_region       = var.region_name
  aws_account_id     = data.aws_caller_identity.current.account_id
  availability_zones = var.availability_zones
  properties = {
    rosa_creator_arn = data.aws_caller_identity.current.arn
  }

  aws_subnet_ids       = aws_subnet.private[*].id
  compute_machine_type = var.compute_machine_type
  machine_cidr         = aws_vpc.main.cidr_block
  multi_az             = true
  replicas             = var.replicas
  sts                  = local.sts_roles
  destroy_timeout      = 60
  aws_private_link     = true
  version              = "openshift-v${var.openshift_version}"
}

resource "ocm_cluster_wait" "rosa_cluster" {
  cluster = ocm_cluster_rosa_classic.rosa_sts_cluster.id
  # timeout in minutes
  timeout = 60
}
