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
- There is currently a race condition when creating the IAM roles which results in a permission denied error. Just run terraform apply again for now until we fix that upstream

## To-Do
Move the vpc section into a sub-module and make it optional
