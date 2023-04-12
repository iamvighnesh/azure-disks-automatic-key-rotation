terraform {
  required_providers {
    azurerm = {
      source  = "azurerm"
      version = ">=3.51"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

resource "azurerm_key_vault" "kv" {
  name                        = var.key_vault_name
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "premium"
  enabled_for_disk_encryption = true
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true
  enable_rbac_authorization   = true
}

resource "azurerm_key_vault_key" "kvk" {
  name         = var.key_vault_key_name
  key_vault_id = azurerm_key_vault.kv.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }

    expire_after         = "P90D"
    notify_before_expiry = "P29D"
  }
}

resource "azurerm_user_assigned_identity" "des_uai" {
  name                = var.disk_encryption_set_uai_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_disk_encryption_set" "des" {
  name                      = var.disk_encryption_set_name
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = azurerm_resource_group.rg.location
  encryption_type           = "EncryptionAtRestWithCustomerKey"
  key_vault_key_id          = azurerm_key_vault_key.kvk.id
  auto_key_rotation_enabled = true
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.des_uai.id
    ]
  }
  depends_on = [
    azurerm_key_vault_key.kvk,
    azurerm_user_assigned_identity.des_uai
  ]
}

resource "azurerm_role_assignment" "des-disk-uai" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_user_assigned_identity.des_uai.principal_id
}

resource "azurerm_role_assignment" "kv-user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Reader"
  principal_id         = data.azurerm_client_config.current.object_id
}
