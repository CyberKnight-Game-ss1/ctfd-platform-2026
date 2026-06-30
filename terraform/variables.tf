variable "project_id" {
  description = "The GCP Project ID"
  type        = string
}

variable "region" {
  description = "The default GCP region"
  type        = string
  default     = "asia-southeast1" # Singapore is usually good for latency in SEA
}

variable "zone" {
  description = "The default GCP zone"
  type        = string
  default     = "asia-southeast1-a"
}

variable "cloudflare_ips" {
  description = "Cloudflare IPv4 ranges"
  type        = list(string)
  default     = [
    "173.245.48.0/20", "103.21.244.0/22", "103.22.200.0/22", "103.31.4.0/22",
    "141.101.64.0/18", "108.162.192.0/18", "190.93.240.0/20", "188.114.96.0/20",
    "197.234.240.0/22", "198.41.128.0/17", "162.158.0.0/15", "104.16.0.0/13",
    "104.24.0.0/14", "172.64.0.0/13", "131.0.72.0/22"
  ]
}

variable "db_password" {
  description = "The database password for CTFd"
  type        = string
  sensitive   = true
}

variable "ctf_domain" {
  description = "The domain name for the CTF"
  type        = string
}

variable "is_practice_mode" {
  description = "Set to true to use spot/preemptible instances for VM2"
  type        = bool
  default     = true
}
