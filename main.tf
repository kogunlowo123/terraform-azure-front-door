resource "azurerm_cdn_frontdoor_profile" "this" {
  name                     = var.profile_name
  resource_group_name      = var.resource_group_name
  sku_name                 = var.sku_name
  response_timeout_seconds = var.response_timeout_seconds

  tags = var.tags
}

resource "azurerm_cdn_frontdoor_endpoint" "this" {
  for_each = var.endpoints

  name                     = each.key
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  enabled                  = each.value.enabled

  tags = var.tags
}

resource "azurerm_cdn_frontdoor_origin_group" "this" {
  for_each = var.origin_groups

  name                     = each.key
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  session_affinity_enabled = each.value.session_affinity_enabled

  restore_traffic_time_to_healed_or_new_endpoint_in_minutes = each.value.restore_traffic_time_to_healed_or_new_endpoint_in_minutes

  dynamic "health_probe" {
    for_each = each.value.health_probe != null ? [each.value.health_probe] : []
    content {
      interval_in_seconds = health_probe.value.interval_in_seconds
      path                = health_probe.value.path
      protocol            = health_probe.value.protocol
      request_type        = health_probe.value.request_type
    }
  }

  load_balancing {
    additional_latency_in_milliseconds = each.value.load_balancing.additional_latency_in_milliseconds
    sample_size                        = each.value.load_balancing.sample_size
    successful_samples_required        = each.value.load_balancing.successful_samples_required
  }
}

resource "azurerm_cdn_frontdoor_origin" "this" {
  for_each = var.origins

  name                           = each.key
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.this[each.value.origin_group_name].id
  host_name                      = each.value.host_name
  http_port                      = each.value.http_port
  https_port                     = each.value.https_port
  origin_host_header             = coalesce(each.value.origin_host_header, each.value.host_name)
  priority                       = each.value.priority
  weight                         = each.value.weight
  certificate_name_check_enabled = each.value.certificate_name_check_enabled
  enabled                        = each.value.enabled

  dynamic "private_link" {
    for_each = each.value.private_link != null ? [each.value.private_link] : []
    content {
      request_message        = private_link.value.request_message
      target_type            = private_link.value.target_type
      location               = private_link.value.location
      private_link_target_id = private_link.value.private_link_target_id
    }
  }
}

resource "azurerm_cdn_frontdoor_custom_domain" "this" {
  for_each = var.custom_domains

  name                     = each.key
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  host_name                = each.value.host_name
  dns_zone_id              = each.value.dns_zone_id

  tls {
    certificate_type        = each.value.tls.certificate_type
    minimum_tls_version     = each.value.tls.minimum_tls_version
    cdn_frontdoor_secret_id = each.value.tls.cdn_frontdoor_secret_id
  }
}

resource "azurerm_cdn_frontdoor_rule_set" "this" {
  for_each = var.rule_sets

  name                     = each.key
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
}

resource "azurerm_cdn_frontdoor_rule" "this" {
  for_each = {
    for r in flatten([
      for rs_key, rs_val in var.rule_sets : [
        for r_key, r_val in rs_val.rules : {
          rule_set_key  = rs_key
          rule_key      = r_key
          composite_key = "${rs_key}-${r_key}"
          rule          = r_val
        }
      ]
    ]) : r.composite_key => r
  }

  name                      = each.value.rule_key
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.this[each.value.rule_set_key].id
  order                     = each.value.rule.order
  behavior_on_match         = each.value.rule.behavior_on_match

  dynamic "conditions" {
    for_each = each.value.rule.conditions != null ? [each.value.rule.conditions] : []
    content {
      dynamic "request_uri_condition" {
        for_each = conditions.value.request_uri_conditions
        content {
          operator         = request_uri_condition.value.operator
          match_values     = request_uri_condition.value.match_values
          negate_condition = request_uri_condition.value.negate_condition
          transforms       = request_uri_condition.value.transforms
        }
      }

      dynamic "request_header_condition" {
        for_each = conditions.value.request_header_conditions
        content {
          header_name      = request_header_condition.value.header_name
          operator         = request_header_condition.value.operator
          match_values     = request_header_condition.value.match_values
          negate_condition = request_header_condition.value.negate_condition
          transforms       = request_header_condition.value.transforms
        }
      }

      dynamic "remote_address_condition" {
        for_each = conditions.value.remote_address_conditions
        content {
          operator         = remote_address_condition.value.operator
          match_values     = remote_address_condition.value.match_values
          negate_condition = remote_address_condition.value.negate_condition
        }
      }
    }
  }

  dynamic "actions" {
    for_each = each.value.rule.actions != null ? [each.value.rule.actions] : []
    content {
      dynamic "url_redirect_action" {
        for_each = actions.value.url_redirect_action != null ? [actions.value.url_redirect_action] : []
        content {
          redirect_type        = url_redirect_action.value.redirect_type
          redirect_protocol    = url_redirect_action.value.redirect_protocol
          destination_hostname = url_redirect_action.value.destination_hostname
          destination_path     = url_redirect_action.value.destination_path
          destination_fragment = url_redirect_action.value.destination_fragment
          query_string         = url_redirect_action.value.query_string
        }
      }

      dynamic "url_rewrite_action" {
        for_each = actions.value.url_rewrite_action != null ? [actions.value.url_rewrite_action] : []
        content {
          source_pattern          = url_rewrite_action.value.source_pattern
          destination             = url_rewrite_action.value.destination
          preserve_unmatched_path = url_rewrite_action.value.preserve_unmatched_path
        }
      }

      dynamic "request_header_action" {
        for_each = actions.value.request_header_action
        content {
          header_action = request_header_action.value.header_action
          header_name   = request_header_action.value.header_name
          value         = request_header_action.value.value
        }
      }

      dynamic "response_header_action" {
        for_each = actions.value.response_header_action
        content {
          header_action = response_header_action.value.header_action
          header_name   = response_header_action.value.header_name
          value         = response_header_action.value.value
        }
      }
    }
  }
}

resource "azurerm_cdn_frontdoor_route" "this" {
  for_each = var.routes

  name                          = each.key
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this[each.value.endpoint_name].id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this[each.value.origin_group_name].id
  cdn_frontdoor_origin_ids      = length(each.value.origin_names) > 0 ? [for o in each.value.origin_names : azurerm_cdn_frontdoor_origin.this[o].id] : [for k, v in azurerm_cdn_frontdoor_origin.this : v.id if var.origins[k].origin_group_name == each.value.origin_group_name]
  forwarding_protocol           = each.value.forwarding_protocol
  https_redirect_enabled        = each.value.https_redirect_enabled
  patterns_to_match             = each.value.patterns_to_match
  supported_protocols           = each.value.supported_protocols
  link_to_default_domain        = each.value.link_to_default_domain
  enabled                       = each.value.enabled

  cdn_frontdoor_custom_domain_ids = length(each.value.custom_domain_names) > 0 ? [for d in each.value.custom_domain_names : azurerm_cdn_frontdoor_custom_domain.this[d].id] : null
  cdn_frontdoor_rule_set_ids      = length(each.value.rule_set_names) > 0 ? [for rs in each.value.rule_set_names : azurerm_cdn_frontdoor_rule_set.this[rs].id] : null

  dynamic "cache" {
    for_each = each.value.cache != null ? [each.value.cache] : []
    content {
      query_string_caching_behavior = cache.value.query_string_caching_behavior
      query_strings                 = cache.value.query_strings
      compression_enabled           = cache.value.compression_enabled
      content_types_to_compress     = cache.value.content_types_to_compress
    }
  }
}

resource "azurerm_cdn_frontdoor_custom_domain_association" "this" {
  for_each = {
    for k, v in var.routes : k => v
    if length(v.custom_domain_names) > 0
  }

  cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.this[each.value.custom_domain_names[0]].id
  cdn_frontdoor_route_ids        = [azurerm_cdn_frontdoor_route.this[each.key].id]
}

resource "azurerm_cdn_frontdoor_firewall_policy" "this" {
  for_each = var.waf_policies

  name                              = each.key
  resource_group_name               = var.resource_group_name
  sku_name                          = var.sku_name
  mode                              = each.value.mode
  enabled                           = each.value.enabled
  redirect_url                      = each.value.redirect_url
  custom_block_response_status_code = each.value.custom_block_response_status_code
  custom_block_response_body        = each.value.custom_block_response_body
  request_body_check_enabled        = each.value.request_body_check_enabled

  dynamic "custom_rule" {
    for_each = each.value.custom_rules
    content {
      name     = custom_rule.value.name
      priority = custom_rule.value.priority
      type     = custom_rule.value.type
      action   = custom_rule.value.action
      enabled  = custom_rule.value.enabled

      rate_limit_duration_in_minutes = custom_rule.value.rate_limit_duration_in_minutes
      rate_limit_threshold           = custom_rule.value.rate_limit_threshold

      dynamic "match_condition" {
        for_each = custom_rule.value.match_conditions
        content {
          match_variable     = match_condition.value.match_variable
          operator           = match_condition.value.operator
          match_values       = match_condition.value.match_values
          selector           = match_condition.value.selector
          negation_condition = match_condition.value.negation_condition
          transforms         = match_condition.value.transforms
        }
      }
    }
  }

  dynamic "managed_rule" {
    for_each = each.value.managed_rules
    content {
      type    = managed_rule.value.type
      version = managed_rule.value.version
      action  = managed_rule.value.action

      dynamic "exclusion" {
        for_each = managed_rule.value.exclusions
        content {
          match_variable = exclusion.value.match_variable
          operator       = exclusion.value.operator
          selector       = exclusion.value.selector
        }
      }

      dynamic "override" {
        for_each = managed_rule.value.overrides
        content {
          rule_group_name = override.value.rule_group_name

          dynamic "rule" {
            for_each = override.value.rules
            content {
              rule_id = rule.value.rule_id
              action  = rule.value.action
              enabled = rule.value.enabled
            }
          }
        }
      }
    }
  }

  tags = var.tags
}

resource "azurerm_cdn_frontdoor_security_policy" "this" {
  for_each = var.security_policies

  name                     = each.key
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.this[each.value.waf_policy_name].id

      association {
        patterns_to_match = each.value.patterns_to_match

        dynamic "domain" {
          for_each = each.value.endpoint_names
          content {
            cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.this[domain.value].id
          }
        }

        dynamic "domain" {
          for_each = each.value.custom_domain_names
          content {
            cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_custom_domain.this[domain.value].id
          }
        }
      }
    }
  }
}
