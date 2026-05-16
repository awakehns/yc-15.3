output "load_balancer_ip" {
  value = yandex_lb_network_load_balancer.lb.listener.*.external_address_spec[0].*.address
}

output "image_url" {
  value = "https://${yandex_storage_bucket.images.bucket}.storage.yandexcloud.net/${yandex_storage_object.image.key}"
}
