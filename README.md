# Домашнее задание к занятию "`Безопасность в облачных провайдерах`" - `Демин Герман`

### Задание 1

Беру целиком папку прошлого задания. Добавляю блоки кода

```
resource "yandex_kms_symmetric_key" "bucket_key" {
  name              = "bucket-key"
  description       = "KMS key for bucket encryption"
  default_algorithm = "AES_256"
  rotation_period   = "8760h"
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
```

И меняю resource "yandex_storage_bucket" в main.tf

[main.tf](main.tf)

`terraform init`

`terraform plan`

`terraform apply`

![tf.jpg](/img/tf.jpg)

Добавляю сертификат

![https](/img/https.jpg)
