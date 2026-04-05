# ── Identity ──────────────────────────────────────────────────────────
variable "name" {
  type        = string
  description = "Databricks workspace name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group."
}

# ── Networking ────────────────────────────────────────────────────────
variable "private_endpoint_subnet_id" {
  type        = string
  description = "Subnet ID for the private endpoint."
}

variable "virtual_network_id" {
  type        = string
  description = "Virtual network ID for private DNS zone link."
}

variable "create_private_dns_zones" {
  type        = bool
  description = "Create private DNS zones for the Databricks private endpoint. Set false if centrally managed."
  default     = true
}

variable "private_dns_zone_ids" {
  type        = map(string)
  description = "Existing private DNS zone IDs keyed by subresource name when create_private_dns_zones = false."
  default     = {}
}

# ── Service-specific ──────────────────────────────────────────────────
variable "sku" {
  type        = string
  description = "Databricks workspace SKU: standard, premium, or trial."
  default     = "premium"
  validation {
    condition     = contains(["standard", "premium", "trial"], var.sku)
    error_message = "sku must be one of: standard, premium, trial."
  }
}

variable "managed_resource_group_name" {
  type        = string
  description = "Name of the managed resource group created by Databricks. Must be unique within the subscription."
  default     = null
}

# ── Operational ───────────────────────────────────────────────────────
variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics workspace ID for diagnostic logs. Empty string to skip."
  default     = ""
}

# ── Tags ──────────────────────────────────────────────────────────────
variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}
