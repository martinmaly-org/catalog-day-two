locals {
  org_id            = data.terraform_remote_state.org.outputs.org_id
  folder_id         = data.terraform_remote_state.org.outputs.folder_id
  billing_account   = data.terraform_remote_state.org.outputs.billing_account
  gh_org            = data.terraform_remote_state.org.outputs.gh_org
  svpc_host_project = data.terraform_remote_state.org.outputs.host_project_id
}

module "cicd-project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 12.0"

  name              = "${var.app_name}-cicd-prj"
  random_project_id = true
  org_id            = local.org_id
  folder_id         = local.folder_id
  billing_account   = local.billing_account
  activate_apis = [
    "compute.googleapis.com",
    "admin.googleapis.com",
    "iam.googleapis.com",
    "billingbudgets.googleapis.com",
    "cloudbilling.googleapis.com",
    "serviceusage.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iamcredentials.googleapis.com", # WIF
    "artifactregistry.googleapis.com",
  ]
}

module "app-project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 12.0"

  name              = "${var.app_name}-app-prj"
  random_project_id = true
  org_id            = local.org_id
  folder_id         = local.folder_id
  billing_account   = local.billing_account
  activate_apis = [
    "compute.googleapis.com",
    "admin.googleapis.com",
    "iam.googleapis.com",
    "billingbudgets.googleapis.com",
    "cloudbilling.googleapis.com",
    "serviceusage.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iamcredentials.googleapis.com", # WIF
    "vpcaccess.googleapis.com",
    "run.googleapis.com"
  ]
  svpc_host_project_id = local.svpc_host_project
}


resource "google_service_account" "sa" {
  project    = module.cicd-project.project_id
  account_id = "${var.app_name}-sa"
}

resource "google_project_iam_member" "cicd-project" {
  project = module.cicd-project.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.sa.email}"
}

resource "google_project_iam_member" "app-project" {
  project = module.app-project.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.sa.email}"
}


module "gh_oidc" {
  source      = "terraform-google-modules/github-actions-runners/google//modules/gh-oidc"
  project_id  = module.cicd-project.project_id
  pool_id     = "${var.app_name}-pool"
  provider_id = "${var.app_name}-gh-provider"
  sa_mapping = {
    "${google_service_account.sa.account_id}-infra" = {
      sa_name   = google_service_account.sa.name
      attribute = "attribute.repository/${local.gh_org}/${github_repository.app-infra.id}"
    },
    // to push container images from app source repo
    "${google_service_account.sa.account_id}-source" = {
      sa_name   = google_service_account.sa.name
      attribute = "attribute.repository/${local.gh_org}/${github_repository.app-source.id}"
    }
  }
}


provider "github" {
  owner = local.gh_org
}

resource "github_repository" "app-infra" {
  name                        = "${var.app_name}-infra"
  allow_merge_commit          = false
  allow_rebase_merge          = false
  allow_update_branch         = true
  delete_branch_on_merge      = true
  has_issues                  = true
  has_projects                = false
  has_wiki                    = false
  vulnerability_alerts        = true
  has_downloads               = false
  squash_merge_commit_message = "BLANK"
  squash_merge_commit_title   = "PR_TITLE"
  auto_init                   = true
}

resource "github_repository" "app-source" {
  name                        = "${var.app_name}-source"
  allow_merge_commit          = false
  allow_rebase_merge          = false
  allow_update_branch         = true
  delete_branch_on_merge      = true
  has_issues                  = true
  has_projects                = false
  has_wiki                    = false
  vulnerability_alerts        = true
  has_downloads               = false
  squash_merge_commit_message = "BLANK"
  squash_merge_commit_title   = "PR_TITLE"
  auto_init                   = true
}


resource "github_actions_secret" "secrets" {
  for_each = {
    "CICD_PROJECT_ID" : module.cicd-project.project_id
    "APP_PROJECT_ID" : module.app-project.project_id
    "SERVICE_ACCOUNT_EMAIL" : google_service_account.sa.email
    "WIF_PROVIDER_NAME" : module.gh_oidc.provider_name
    "TF_BACKEND" : google_storage_bucket.backend.name
    "ORG_ID" : local.org_id,
    "FOLDER_ID" : local.folder_id,
    "BILLING_ACCOUNT" : local.billing_account
    "APP_NAME" : var.app_name
    "HOST_PROJECT_ID" : local.svpc_host_project
  }

  repository      = github_repository.app-infra.id
  secret_name     = each.key
  plaintext_value = each.value
  depends_on = [
    github_repository.app-infra
  ]
}


resource "github_actions_secret" "source-secrets" {
  for_each = {
    "CICD_PROJECT_ID" : module.cicd-project.project_id
    "SERVICE_ACCOUNT_EMAIL" : google_service_account.sa.email
    "WIF_PROVIDER_NAME" : module.gh_oidc.provider_name
    "GAR_LOCATION" : google_artifact_registry_repository.tf-image-repo.location
    "GAR_REPO" : google_artifact_registry_repository.tf-image-repo.repository_id
    "APP_NAME" : var.app_name
  }

  repository      = github_repository.app-source.id
  secret_name     = each.key
  plaintext_value = each.value
  depends_on = [
    github_repository.app-infra
  ]
}


resource "google_storage_bucket" "backend" {
  name                     = "${var.app_name}-app-backend-${module.cicd-project.project_id}"
  project                  = module.cicd-project.project_id
  location                 = "US"
  force_destroy            = true
  public_access_prevention = "enforced"
}

data "terraform_remote_state" "org" {
  backend = "gcs"

  config = {
    bucket = var.org_remote_state
    prefix = "terraform/fs"
  }
}
