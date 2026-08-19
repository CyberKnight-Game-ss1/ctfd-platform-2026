# Random suffix để đảm bảo tên bucket GCS là unique toàn cầu
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# ============================================================
# Google Cloud Storage (GCS) Bucket
# Dùng để lưu PCAP traffic và database backups
# Lifecycle:
#   - Sau 7 ngày:  chuyển sang NEARLINE  (tiết kiệm ~40% so với STANDARD)
#   - Sau 30 ngày: chuyển sang COLDLINE  (tiết kiệm ~80% so với STANDARD)
# ============================================================
resource "google_storage_bucket" "ctf_storage" {
  name          = "ctf-storage-${random_id.bucket_suffix.hex}"
  location      = var.region
  force_destroy = true  # Đổi thành false khi thi đấu thật

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

# ============================================================
# Cloud Scheduler - Tự động dừng VM2 lúc 00:00 ICT (tiết kiệm chi phí)
# ============================================================
resource "google_cloud_scheduler_job" "stop_vm2" {
  name        = "stop-vm2-nightly"
  description = "Dừng VM2 (Challenge Server) sau giờ thi đấu"
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

# ============================================================
# Cloud Scheduler - Tự động khởi động VM2 lúc 07:30 ICT
# ============================================================
resource "google_cloud_scheduler_job" "start_vm2" {
  name        = "start-vm2-morning"
  description = "Khởi động VM2 (Challenge Server) trước giờ thi đấu"
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
