variable "yc_token" {
  sensitive = true
}

variable "cloud_id" {}

variable "folder_id" {}

variable "zone" {
  default = "ru-central1-a"
}

variable "bucket_name" {
  default = "netology-bucket-example-2026"
}
