# Private IP access for Cloud SQL
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

resource "google_sql_database_instance" "ctf_postgres" {
  name             = "ctf-postgres-instance"
  database_version = "POSTGRES_15"
  region           = var.region
  depends_on       = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-f1-micro" # Use e.g. db-custom-2-8192 for production
    
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.ctf_vpc.id
    }

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
      start_time                     = "03:00"
    }
  }
  
  deletion_protection = false # Set to true for actual event
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

# Secret Manager to store DB connection
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

resource "google_secret_manager_secret_iam_member" "vm_sa_secret_access" {
  secret_id = google_secret_manager_secret.db_conn_secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.vm_sa.email}"
}
