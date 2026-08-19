output "vm1_web_public_ip" {
  description = "Public IP của VM1 (Web Server) - dùng để trỏ DNS Cloudflare"
  value       = google_compute_instance.vm1_web.network_interface[0].access_config[0].nat_ip
}

output "vm2_challenge_public_ip" {
  description = "Public IP của VM2 (Challenge Server)"
  value       = google_compute_instance.vm2_challenge.network_interface[0].access_config[0].nat_ip
}

output "cloud_sql_private_ip" {
  description = "Private IP của Cloud SQL PostgreSQL (chỉ truy cập được từ trong VPC)"
  value       = google_sql_database_instance.ctf_postgres.private_ip_address
}

output "database_url_secret_name" {
  description = "Tên Secret trong GCP Secret Manager chứa DATABASE_URL của CTFd"
  value       = google_secret_manager_secret.db_conn_secret.secret_id
}

output "gcs_bucket_name" {
  description = "Tên GCS bucket lưu PCAP và backups"
  value       = google_storage_bucket.ctf_storage.name
}
