resource "google_compute_network" "ctf_vpc" {
  name                    = "ctf-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "ctf_subnet" {
  name          = "ctf-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.ctf_vpc.id
}

# Cho phép HTTPS/HTTP từ Cloudflare vào VM1 (Web) và VM2 (Challenge public ports nếu cần)
resource "google_compute_firewall" "allow_cloudflare_https" {
  name    = "allow-cloudflare-https"
  network = google_compute_network.ctf_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["443", "80"] # 80 cho ACME challenge/redirect
  }

  source_ranges = var.cloudflare_ips
  target_tags   = ["web-server", "challenge-server"]
}

# Cho phép mTLS Docker (port 2376) nội bộ từ VM1 đến VM2
resource "google_compute_firewall" "allow_internal_mtls" {
  name    = "allow-internal-mtls"
  network = google_compute_network.ctf_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["2376"]
  }

  source_ranges = ["10.0.0.0/24"]
  target_tags   = ["challenge-server"]
}

# Cho phép SSH qua Identity-Aware Proxy (IAP) - không cần mở port 22 ra internet
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "allow-iap-ssh"
  network = google_compute_network.ctf_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # IP range chính thức của GCP IAP proxy
  source_ranges = ["35.235.240.0/20"]
}
