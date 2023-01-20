module "service_account" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "~> 4.1"
  project_id = var.project_id
  prefix     = "sa-cloud-run"
  names      = ["simple"]
}

module "cloud_run" {
  source  = "GoogleCloudPlatform/cloud-run/google"
  version = "~> 0.4"

  service_name          = "${var.app_name}-run"
  project_id            = var.project_id
  location              = "us-central1"
  image                 = var.image_url
  service_account_email = module.service_account.email
  members               = ["allUsers"]

  template_annotations = {
    "autoscaling.knative.dev/maxScale" = 4
    "autoscaling.knative.dev/minScale" = 2
    # "run.googleapis.com/vpc-access-connector" = element(tolist(module.serverless_connector.connector_ids), 1)
    # "run.googleapis.com/vpc-access-egress"    = "all-traffic"
  }
}
# TODO
# module "serverless_connector" {
#   source  = "terraform-google-modules/network/google//modules/vpc-serverless-connector-beta"
#   version = "~> 4.0"

#   project_id = var.project_id
#   vpc_connectors = [{
#     name            = "central-serverless"
#     region          = "us-central1"
#     subnet_name     = var.subnet_name
#     host_project_id = var.host_project_id
#     machine_type    = "e2-micro"
#     min_instances   = 2
#     max_instances   = 3
#   }]
# }