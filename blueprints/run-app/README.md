# Run App

This blueprint provides an opinionated setup for using Cloud Run in our org.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| app\_name | App name | `string` | n/a | yes |
| host\_project\_id | SVPC Host Project ID | `string` | n/a | yes |
| image\_url | Image URL | `string` | n/a | yes |
| project\_id | Project ID | `string` | n/a | yes |
| subnet\_name | Subnet for serverless connector (todo) | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| url | Cloud Run service URL |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
