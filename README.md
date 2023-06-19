# Terraform plan to make a privatelink ROSA cluster
Creates:

- VPCs
- Subnets
- NAT Gateways
- Route tables
- Internet gateway
- ROSA Account Roles
- ROSA Operator Roles
- Unmanaged OIDC provider
- COMING SOON: CloudFront Distribution in front of OIDC config bucket

## Usage:

```
terraform init
terraform apply
```

## Notes:
- The OIDC provider is by default created in a public bucket, as it needs to have a https URL in front of it. This causes security alarms with most customers, hence the CloudFront workaround.
- The customer needs to manually apply the restricted bucket policy after running terraform. Note that this will create a config drift with the module until we get a chance to make that bit optional
- There is currently a race condition when creating the IAM roles which results in a permission denied error. Just run terraform apply again for now until we fix that upstream

## To-Do
Move the vpc section into a sub-module and make it optional
