output "profile_id" {
  description = "Resource ID of the Front Door profile."
  value       = azurerm_cdn_frontdoor_profile.this.id
}

output "profile_name" {
  description = "Name of the Front Door profile."
  value       = azurerm_cdn_frontdoor_profile.this.name
}

output "profile_resource_guid" {
  description = "Resource GUID of the Front Door profile."
  value       = azurerm_cdn_frontdoor_profile.this.resource_guid
}

output "endpoint_ids" {
  description = "Map of endpoint names to their resource IDs."
  value       = { for k, v in azurerm_cdn_frontdoor_endpoint.this : k => v.id }
}

output "endpoint_host_names" {
  description = "Map of endpoint names to their host names."
  value       = { for k, v in azurerm_cdn_frontdoor_endpoint.this : k => v.host_name }
}

output "origin_group_ids" {
  description = "Map of origin group names to their resource IDs."
  value       = { for k, v in azurerm_cdn_frontdoor_origin_group.this : k => v.id }
}

output "origin_ids" {
  description = "Map of origin names to their resource IDs."
  value       = { for k, v in azurerm_cdn_frontdoor_origin.this : k => v.id }
}

output "route_ids" {
  description = "Map of route names to their resource IDs."
  value       = { for k, v in azurerm_cdn_frontdoor_route.this : k => v.id }
}

output "custom_domain_ids" {
  description = "Map of custom domain names to their resource IDs."
  value       = { for k, v in azurerm_cdn_frontdoor_custom_domain.this : k => v.id }
}

output "custom_domain_validation_tokens" {
  description = "Map of custom domain names to their validation tokens."
  value       = { for k, v in azurerm_cdn_frontdoor_custom_domain.this : k => v.validation_token }
}

output "rule_set_ids" {
  description = "Map of rule set names to their resource IDs."
  value       = { for k, v in azurerm_cdn_frontdoor_rule_set.this : k => v.id }
}

output "waf_policy_ids" {
  description = "Map of WAF policy names to their resource IDs."
  value       = { for k, v in azurerm_cdn_frontdoor_firewall_policy.this : k => v.id }
}

output "waf_policy_frontend_endpoint_ids" {
  description = "Map of WAF policy names to their frontend endpoint IDs."
  value       = { for k, v in azurerm_cdn_frontdoor_firewall_policy.this : k => v.frontend_endpoint_ids }
}

output "security_policy_ids" {
  description = "Map of security policy names to their resource IDs."
  value       = { for k, v in azurerm_cdn_frontdoor_security_policy.this : k => v.id }
}
