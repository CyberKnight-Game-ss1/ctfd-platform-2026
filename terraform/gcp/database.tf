# ============================================================
# Private IP Peering để Cloud SQL không có public IP
# ============================================================
resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.ctf_vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.ctf_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# ============================================================
# Cloud SQL PostgreSQL 15
# - Không có public IP (chỉ private IP trong VPC)
# - Bật Point-in-Time Recovery (PITR) và backup hàng ngày lúc 03:00
# - Dùng tier db-f1-micro cho luyện tập; nâng lên db-custom-2-8192 cho thi đấu thật
# ============================================================
resource "google_sql_database_instance" "ctf_postgres" {
  name             = "ctf-postgres-instance"
  database_version = "POSTGRES_15"
  region           = var.region
  depends_on       = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-f1-micro" # Nâng lên db-custom-2-8192 khi tổ chức thi thật

    ip_configuration {
      ipv4_enabled    = false                         # Không cấp public IP cho DB
      private_network = google_compute_network.ctf_vpc.id
    }

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
      start_time                     = "03:00"        # Backup lúc 3:00 AM ICT
    }
  }

  # Đổi thành true trước khi tổ chức thi đấu thật để tránh xóa nhầm
  deletion_protection = false
}

resource "google_sql_user" "ctfd_user" {
  name     = "ctfd"
  instance = google_sql_database_instance.ctf_postgres.name
  password = var.db_password
}

resource "google_sql_database" "ctfd_db" {
  name     = "ctfd"
  instance = google_sql_database_instance.ctf_postgres.name
}

# ============================================================
# Secret Manager - lưu DATABASE_URL để VM lấy qua API
# ============================================================
resource "google_secret_manager_secret" "db_conn_secret" {
  secret_id = "ctfd-db-connection"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_conn_secret_version" {
  secret      = google_secret_manager_secret.db_conn_secret.id
  secret_data = "postgresql://ctfd:${var.db_password}@${google_sql_database_instance.ctf_postgres.private_ip_address}:5432/ctfd"
}

# Cấp quyền đọc secret cho VM Service Account
resource "google_secret_manager_secret_iam_member" "vm_sa_secret_access" {
  secret_id = google_secret_manager_secret.db_conn_secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.vm_sa.email}"
}
