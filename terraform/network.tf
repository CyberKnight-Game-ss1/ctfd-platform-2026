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

# Allow HTTPS traffic from Cloudflare to VM1 and VM2
resource "google_compute_firewall" "allow_cloudflare_https" {
  name    = "allow-cloudflare-https"
  network = google_compute_network.ctf_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["443", "80"] # 80 for acme challenge/redirects
  }

  source_ranges = var.cloudflare_ips
  target_tags   = ["web-server", "challenge-server"]
}

# Allow internal mTLS traffic (port 2376) between VM1 and VM2
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

# Allow SSH from Identity-Aware Proxy (IAP) for secure management
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "allow-iap-ssh"
  network = google_compute_network.ctf_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
}
