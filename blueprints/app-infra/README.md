# App Infra

This blueprint provides an opinionated setup for new application including repository setup, CI/CD project, app projects, Artifact Registry etc.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| app\_name | Name of the app | `string` | n/a | yes |
| org\_remote\_state | Org state bucket | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| app-infra-project-id | Project for deploying application resources |
| cicd-project-id | Project for deploying CI/CD resources |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
