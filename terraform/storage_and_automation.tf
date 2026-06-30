# Random suffix for globally unique bucket names
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# GCS Bucket for backups and PCAPs
resource "google_storage_bucket" "ctf_storage" {
  name          = "ctf-storage-${random_id.bucket_suffix.hex}"
  location      = var.region
  force_destroy = true # Change to false for production

  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }
}

# Cloud Scheduler to Stop VM2 at midnight (00:00) ICT
resource "google_cloud_scheduler_job" "stop_vm2" {
  name        = "stop-vm2-nightly"
  description = "Stop VM2 outside competition hours"
  schedule    = "0 0 * * *"
  time_zone   = "Asia/Ho_Chi_Minh"

  http_target {
    http_method = "POST"
    uri         = "https://compute.googleapis.com/compute/v1/projects/${var.project_id}/zones/${var.zone}/instances/${google_compute_instance.vm2_challenge.name}/stop"
    
    oauth_token {
      service_account_email = google_service_account.vm_sa.email
    }
  }
}

# Cloud Scheduler to Start VM2 at 07:30 ICT
resource "google_cloud_scheduler_job" "start_vm2" {
  name        = "start-vm2-morning"
  description = "Start VM2 before competition hours"
  schedule    = "30 7 * * *"
  time_zone   = "Asia/Ho_Chi_Minh"

  http_target {
    http_method = "POST"
    uri         = "https://compute.googleapis.com/compute/v1/projects/${var.project_id}/zones/${var.zone}/instances/${google_compute_instance.vm2_challenge.name}/start"
    
    oauth_token {
      service_account_email = google_service_account.vm_sa.email
    }
  }
}
