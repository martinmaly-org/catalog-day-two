variable "app_name" {
  description = "Name of the app"
  type        = string
}

# variable "infra_roles" {
#   description = "Roles for the SA in the infra project."
#   type = list(string)
# }

variable "org_remote_state" {
  description = "Org state bucket"
  type        = string
}
