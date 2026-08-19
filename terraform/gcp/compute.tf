# Service Account dùng chung cho cả 2 VM
resource "google_service_account" "vm_sa" {
  account_id   = "ctf-vm-sa"
  display_name = "CTF VM Service Account"
}

# Cho phép VM ghi logs lên Cloud Logging
resource "google_project_iam_member" "vm_sa_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.vm_sa.email}"
}

# Cho phép Service Account dừng/khởi động instances qua Cloud Scheduler
resource "google_project_iam_member" "vm_sa_compute_admin" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.vm_sa.email}"
}

# ============================================================
# VM1 - Web Server (CTFd + Redis + Nginx)
# Machine type e2-medium: 2 vCPU, 4 GB RAM
# ============================================================
resource "google_compute_instance" "vm1_web" {
  name         = "ctf-vm1-web"
  machine_type = "e2-medium"
  zone         = var.zone

  tags = ["web-server"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 30 # GB
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.ctf_subnet.id
    access_config {
      # Tự động gán Ephemeral public IP
      # Cloudflare proxy sẽ forward traffic đến IP này
    }
  }

  service_account {
    email  = google_service_account.vm_sa.email
    scopes = ["cloud-platform"]
  }

  # Thêm SSH key vào project metadata hoặc bật OS Login thay vì hardcode ở đây
  # metadata = {
  #   ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  # }
}

# ============================================================
# VM2 - Challenge Server (Docker + K3s + CTFd Whale)
# Machine type e2-standard-2: 2 vCPU, 8 GB RAM
# Dùng Spot/Preemptible khi is_practice_mode = true để tiết kiệm chi phí
# ============================================================
resource "google_compute_instance" "vm2_challenge" {
  name         = "ctf-vm2-challenge"
  machine_type = "e2-standard-2"
  zone         = var.zone

  tags = ["challenge-server"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 50 # GB - cần nhiều dung lượng cho Docker images của challenges
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.ctf_subnet.id
    access_config {
      # Ephemeral public IP
    }
  }

  service_account {
    email  = google_service_account.vm_sa.email
    scopes = ["cloud-platform"]
  }

  scheduling {
    preemptible        = var.is_practice_mode
    automatic_restart  = !var.is_practice_mode
    provisioning_model = var.is_practice_mode ? "SPOT" : "STANDARD"
  }
}
