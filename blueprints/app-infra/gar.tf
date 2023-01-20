locals {
  gar_name = split("/", google_artifact_registry_repository.tf-image-repo.name)[length(split("/", google_artifact_registry_repository.tf-image-repo.name)) - 1]
}

resource "google_artifact_registry_repository" "tf-image-repo" {
  provider = google-beta
  project  = module.cicd-project.project_id

  location      = "us-central1"
  repository_id = "${var.app_name}-images"
  description   = "Docker repository for ${var.app_name} images."
  format        = "DOCKER"
}

# Grant CB SA permissions to push to repo
resource "google_artifact_registry_repository_iam_member" "push_images" {
  provider = google-beta
  project  = module.cicd-project.project_id

  location   = google_artifact_registry_repository.tf-image-repo.location
  repository = google_artifact_registry_repository.tf-image-repo.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.sa.email}"
}

# Grant CR SA permissions to pull

resource "google_project_service_identity" "run_sa" {
  provider = google-beta
  project  = module.app-project.project_id
  service  = "run.googleapis.com"
}

resource "google_artifact_registry_repository_iam_member" "pull_images" {
  provider = google-beta
  project  = module.cicd-project.project_id

  location   = google_artifact_registry_repository.tf-image-repo.location
  repository = google_artifact_registry_repository.tf-image-repo.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_project_service_identity.run_sa.email}"
}
