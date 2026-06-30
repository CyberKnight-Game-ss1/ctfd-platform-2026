resource "google_service_account" "vm_sa" {
  account_id   = "ctf-vm-sa"
  display_name = "CTF VM Service Account"
}

# Allow VMs to write logs to Cloud Logging
resource "google_project_iam_member" "vm_sa_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.vm_sa.email}"
}

# Allow SA to stop/start instances via Scheduler
resource "google_project_iam_member" "vm_sa_compute_admin" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.vm_sa.email}"
}

resource "google_compute_instance" "vm1_web" {
  name         = "ctf-vm1-web"
  machine_type = "e2-medium"
  zone         = var.zone

  tags = ["web-server"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 30
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.ctf_subnet.id
    access_config {
      # Ephemeral public IP, Cloudflare proxy will forward to this IP
    }
  }

  service_account {
    email  = google_service_account.vm_sa.email
    scopes = ["cloud-platform"]
  }

  # Ensure user adds their SSH key to project metadata or OS login
  # metadata = {
  #   ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  # }
}

resource "google_compute_instance" "vm2_challenge" {
  name         = "ctf-vm2-challenge"
  machine_type = "e2-standard-2"
  zone         = var.zone

  tags = ["challenge-server"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 50
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
    preemptible                 = var.is_practice_mode
    automatic_restart           = !var.is_practice_mode
    provisioning_model          = var.is_practice_mode ? "SPOT" : "STANDARD"
  }
}
