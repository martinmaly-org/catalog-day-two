variable "app_name" {
  description = "App name"
  type        = string
}


variable "image_url" {
  description = "Image URL"
  type        = string
}

variable "project_id" {
  description = "Project ID"
  type        = string
}

variable "host_project_id" {
  description = "SVPC Host Project ID"
  type        = string
}

variable "subnet_name" {
  description = "Subnet to deploy run"
  type        = string
}