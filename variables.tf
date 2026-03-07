variable "resource_group_name" {
  description = "Name of the resource group where resources will be created."
  type        = string

  validation {
    condition     = length(var.resource_group_name) > 0 && length(var.resource_group_name) <= 90
    error_message = "Resource group name must be between 1 and 90 characters."
  }
}

variable "profile_name" {
  description = "Name of the Azure Front Door profile."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{0,63}$", var.profile_name))
    error_message = "Profile name must start with a letter, be 1-64 characters, and contain only letters, numbers, and hyphens."
  }
}

variable "sku_name" {
  description = "SKU of the Front Door profile."
  type        = string
  default     = "Standard_AzureFrontDoor"

  validation {
    condition     = contains(["Standard_AzureFrontDoor", "Premium_AzureFrontDoor"], var.sku_name)
    error_message = "SKU must be Standard_AzureFrontDoor or Premium_AzureFrontDoor."
  }
}

variable "response_timeout_seconds" {
  description = "Response timeout in seconds for the Front Door profile."
  type        = number
  default     = 120

  validation {
    condition     = var.response_timeout_seconds >= 16 && var.response_timeout_seconds <= 240
    error_message = "Response timeout must be between 16 and 240 seconds."
  }
}

variable "endpoints" {
  description = "Map of Front Door endpoints."
  type = map(object({
    enabled = optional(bool, true)
  }))
  default = {}
}

variable "origin_groups" {
  description = "Map of origin groups."
  type = map(object({
    session_affinity_enabled = optional(bool, false)

    restore_traffic_time_to_healed_or_new_endpoint_in_minutes = optional(number, 10)

    health_probe = optional(object({
      interval_in_seconds = optional(number, 100)
      path                = optional(string, "/")
      protocol            = optional(string, "Https")
      request_type        = optional(string, "HEAD")
    }), null)

    load_balancing = optional(object({
      additional_latency_in_milliseconds = optional(number, 50)
      sample_size                        = optional(number, 4)
      successful_samples_required        = optional(number, 3)
    }), {})
  }))
  default = {}
}

variable "origins" {
  description = "Map of origins within origin groups."
  type = map(object({
    origin_group_name                = string
    host_name                        = string
    http_port                        = optional(number, 80)
    https_port                       = optional(number, 443)
    origin_host_header               = optional(string, null)
    priority                         = optional(number, 1)
    weight                           = optional(number, 1000)
    certificate_name_check_enabled   = optional(bool, true)
    enabled                          = optional(bool, true)

    private_link = optional(object({
      request_message        = optional(string, "Front Door Private Link")
      target_type            = optional(string, null)
      location               = string
      private_link_target_id = string
    }), null)
  }))
  default = {}
}

variable "routes" {
  description = "Map of routes for Front Door endpoints."
  type = map(object({
    endpoint_name          = string
    origin_group_name      = string
    origin_names           = optional(list(string), [])
    forwarding_protocol    = optional(string, "HttpsOnly")
    https_redirect_enabled = optional(bool, true)
    patterns_to_match      = optional(list(string), ["/*"])
    supported_protocols    = optional(list(string), ["Http", "Https"])
    link_to_default_domain = optional(bool, true)
    custom_domain_names    = optional(list(string), [])
    enabled                = optional(bool, true)

    cache = optional(object({
      query_string_caching_behavior = optional(string, "IgnoreQueryString")
      query_strings                 = optional(list(string), [])
      compression_enabled           = optional(bool, false)
      content_types_to_compress     = optional(list(string), [])
    }), null)

    rule_set_names = optional(list(string), [])
  }))
  default = {}
}

variable "rule_sets" {
  description = "Map of rule sets."
  type = map(object({
    rules = map(object({
      order             = number
      behavior_on_match = optional(string, "Continue")

      conditions = optional(object({
        request_uri_conditions = optional(list(object({
          operator         = string
          match_values     = list(string)
          negate_condition = optional(bool, false)
          transforms       = optional(list(string), [])
        })), [])

        request_header_conditions = optional(list(object({
          header_name      = string
          operator         = string
          match_values     = optional(list(string), [])
          negate_condition = optional(bool, false)
          transforms       = optional(list(string), [])
        })), [])

        remote_address_conditions = optional(list(object({
          operator         = string
          match_values     = optional(list(string), [])
          negate_condition = optional(bool, false)
        })), [])
      }), null)

      actions = optional(object({
        url_redirect_action = optional(object({
          redirect_type        = string
          redirect_protocol    = optional(string, "Https")
          destination_hostname = optional(string, "")
          destination_path     = optional(string, "")
          destination_fragment = optional(string, "")
          query_string         = optional(string, "")
        }), null)

        url_rewrite_action = optional(object({
          source_pattern          = string
          destination             = string
          preserve_unmatched_path = optional(bool, true)
        }), null)

        request_header_action = optional(list(object({
          header_action = string
          header_name   = string
          value         = optional(string, null)
        })), [])

        response_header_action = optional(list(object({
          header_action = string
          header_name   = string
          value         = optional(string, null)
        })), [])
      }), null)
    }))
  }))
  default = {}
}

variable "custom_domains" {
  description = "Map of custom domains."
  type = map(object({
    host_name = string
    tls = optional(object({
      certificate_type    = optional(string, "ManagedCertificate")
      minimum_tls_version = optional(string, "TLS12")
      cdn_frontdoor_secret_id = optional(string, null)
    }), {})
    dns_zone_id = optional(string, null)
  }))
  default = {}
}

variable "waf_policies" {
  description = "Map of WAF policies."
  type = map(object({
    mode    = optional(string, "Prevention")
    enabled = optional(bool, true)

    redirect_url                      = optional(string, null)
    custom_block_response_status_code = optional(number, 403)
    custom_block_response_body        = optional(string, null)

    request_body_check_enabled = optional(bool, true)

    custom_rules = optional(list(object({
      name     = string
      priority = number
      type     = string
      action   = string
      enabled  = optional(bool, true)

      match_conditions = list(object({
        match_variable     = string
        operator           = string
        match_values       = list(string)
        selector           = optional(string, null)
        negation_condition = optional(bool, false)
        transforms         = optional(list(string), [])
      }))

      rate_limit_duration_in_minutes = optional(number, 1)
      rate_limit_threshold           = optional(number, 10)
    })), [])

    managed_rules = optional(list(object({
      type    = string
      version = string
      action  = optional(string, "Block")

      exclusions = optional(list(object({
        match_variable = string
        operator       = string
        selector       = string
      })), [])

      overrides = optional(list(object({
        rule_group_name = string
        rules = optional(list(object({
          rule_id = string
          action  = string
          enabled = optional(bool, true)
        })), [])
      })), [])
    })), [])
  }))
  default = {}
}

variable "security_policies" {
  description = "Map of security policies linking WAF to endpoints/domains."
  type = map(object({
    waf_policy_name = string
    patterns_to_match = optional(list(string), ["/*"])
    endpoint_names    = optional(list(string), [])
    custom_domain_names = optional(list(string), [])
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
