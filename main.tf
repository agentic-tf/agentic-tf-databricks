terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.0" }
  }
}

locals {
  private_dns_zone_ids = var.create_private_dns_zones ? {
    databricks_ui_api = azurerm_private_dns_zone.databricks[0].id
  } : var.private_dns_zone_ids
}

resource "azurerm_databricks_workspace" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku

  managed_resource_group_name = var.managed_resource_group_name

  # ── Security hardening ────────────────────────────────────────────────
  # I.AZR.0108 — customer-managed VNet with no public access
  public_network_access_enabled = "Disabled"

  custom_parameters {
    # Secure cluster connectivity — no public IPs on data-plane nodes
    no_public_ip = true
  }

  tags = var.tags
}

# ── Private Endpoint ──────────────────────────────────────────────────
resource "azurerm_private_endpoint" "databricks" {
  name                = "${var.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.name}-psc"
    private_connection_resource_id = azurerm_databricks_workspace.this.id
    subresource_names              = ["databricks_ui_api"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = contains(keys(local.private_dns_zone_ids), "databricks_ui_api") ? [1] : []
    content {
      name                 = "databricks-dns-group"
      private_dns_zone_ids = [local.private_dns_zone_ids["databricks_ui_api"]]
    }
  }

  tags = var.tags
}

# ── Private DNS Zone ──────────────────────────────────────────────────
resource "azurerm_private_dns_zone" "databricks" {
  count               = var.create_private_dns_zones ? 1 : 0
  name                = "privatelink.azuredatabricks.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "databricks" {
  count                 = var.create_private_dns_zones ? 1 : 0
  name                  = "${var.name}-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.databricks[0].name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
  tags                  = var.tags
}

# ── Diagnostic Settings (I.AZR.0013) ─────────────────────────────────
resource "azurerm_monitor_diagnostic_setting" "databricks" {
  count = var.log_analytics_workspace_id != "" ? 1 : 0

  name                       = "${var.name}-diag"
  target_resource_id         = azurerm_databricks_workspace.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "dbfs"
  }

  enabled_log {
    category = "clusters"
  }

  enabled_log {
    category = "accounts"
  }

  enabled_log {
    category = "jobs"
  }

  enabled_log {
    category = "notebook"
  }

  enabled_log {
    category = "ssh"
  }

  enabled_log {
    category = "workspace"
  }

  enabled_log {
    category = "secrets"
  }

  enabled_log {
    category = "sqlPermissions"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
