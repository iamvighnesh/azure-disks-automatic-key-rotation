variable "resource_group_name" {
  type = string
  default = "rg-diskencryptionset-demos"
}

variable "resource_group_location" {
  type = string
  default = "East US"
}

variable "key_vault_name" {
  type = string
  default = "kvdesdemo"
}

variable "key_vault_key_name" {
  type = string
  default = "kvdesdemo-encryption-key"
}

variable "disk_encryption_set_uai_name" {
  type = string
  default = "uai-diskencryptionset-demos"
}


variable "disk_encryption_set_name" {
  type = string
  default = "des-diskencryptionset-demos"
}
