output "cicd-project-id" {
  description = "Project for deploying CI/CD resources"
  value = module.cicd-project.project_id
}

output "app-infra-project-id" {
  description = "Project for deploying application resources"
  value = module.app-project.project_id
}