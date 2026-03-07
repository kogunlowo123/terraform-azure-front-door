locals {
  common_tags = merge(var.tags, {
    ManagedBy = "Terraform"
    Module    = "terraform-azure-front-door"
  })

  is_premium = var.sku_name == "Premium_AzureFrontDoor"

  origin_group_ids = {
    for k, v in azurerm_cdn_frontdoor_origin_group.this : k => v.id
  }

  origin_ids = {
    for k, v in azurerm_cdn_frontdoor_origin.this : k => v.id
  }

  endpoint_ids = {
    for k, v in azurerm_cdn_frontdoor_endpoint.this : k => v.id
  }

  custom_domain_ids = {
    for k, v in azurerm_cdn_frontdoor_custom_domain.this : k => v.id
  }

  rule_set_ids = {
    for k, v in azurerm_cdn_frontdoor_rule_set.this : k => v.id
  }

  waf_policy_ids = {
    for k, v in azurerm_cdn_frontdoor_firewall_policy.this : k => v.id
  }

  # Flatten rules from rule sets for resource creation
  rules_flat = flatten([
    for rs_key, rs_val in var.rule_sets : [
      for r_key, r_val in rs_val.rules : {
        rule_set_key  = rs_key
        rule_key      = r_key
        composite_key = "${rs_key}-${r_key}"
        rule          = r_val
      }
    ]
  ])

  rules_map = {
    for r in local.rules_flat : r.composite_key => r
  }
}
