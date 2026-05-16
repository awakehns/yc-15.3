resource "yandex_vpc_network" "network" {
  name = "netology-network"
}

resource "yandex_vpc_subnet" "public" {
  name           = "public-subnet"
  zone           = var.zone
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["10.10.0.0/24"]
}

# =========================
# Object Storage bucket
# =========================

resource "yandex_storage_bucket" "images" {
  bucket    = var.bucket_name
  folder_id = var.folder_id

  anonymous_access_flags {
    read = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = yandex_kms_symmetric_key.bucket_key.id
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "yandex_storage_object" "image" {
  bucket = yandex_storage_bucket.images.bucket
  key    = "image.jpg"
  source = "image.jpg"

  content_type = "image/jpeg"
}

# =========================
# Service account
# =========================

resource "yandex_iam_service_account" "sa" {
  name = "ig-service-account"
}

resource "yandex_resourcemanager_folder_iam_member" "editor" {
  folder_id = var.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

resource "yandex_iam_service_account_static_access_key" "sa_key" {
  service_account_id = yandex_iam_service_account.sa.id
  description        = "static access key for object storage"
}

# =========================
# Instance Group
# =========================

resource "yandex_compute_instance_group" "lamp_group" {
  name               = "lamp-group"
  folder_id          = var.folder_id
  service_account_id = yandex_iam_service_account.sa.id

  instance_template {
    platform_id = "standard-v1"

    resources {
      memory = 2
      cores  = 2
    }

    boot_disk {
      initialize_params {
        image_id = "fd827b91d99psvq5fjit"
        size     = 10
      }
    }

    network_interface {
      network_id = yandex_vpc_network.network.id
      subnet_ids = [yandex_vpc_subnet.public.id]
      nat        = true
    }

    metadata = {
      user-data = <<EOF
#cloud-config
write_files:
  - path: /var/www/html/index.html
    content: |
      <html>
      <body>
      <h1>LAMP Instance Group</h1>
      <img src="https://${yandex_storage_bucket.images.bucket}.storage.yandexcloud.net/${yandex_storage_object.image.key}" width="500">
      </body>
      </html>

runcmd:
  - systemctl restart apache2
EOF
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    zones = [var.zone]
  }

  deploy_policy {
    max_unavailable = 1
    max_expansion   = 0
  }

  health_check {
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2

    http_options {
      port = 80
      path = "/"
    }
  }

  load_balancer {
    target_group_name = "lamp-target-group"
  }
}

# =========================
# Network Load Balancer
# =========================

resource "yandex_lb_network_load_balancer" "lb" {
  name = "lamp-balancer"

  listener {
    name = "http"

    port = 80

    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_compute_instance_group.lamp_group.load_balancer.0.target_group_id

    healthcheck {
      name = "http"

      http_options {
        port = 80
        path = "/"
      }
    }
  }
}

resource "yandex_resourcemanager_folder_iam_member" "kms" {
  folder_id = var.folder_id
  role      = "kms.keys.encrypterDecrypter"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

resource "yandex_kms_symmetric_key" "bucket_key" {
  name              = "bucket-key"
  description       = "KMS key for bucket encryption"
  default_algorithm = "AES_256"
  rotation_period   = "8760h"
}
