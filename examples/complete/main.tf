provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "rg-front-door-complete"
  location = "East US"
}

resource "azurerm_dns_zone" "example" {
  name                = "example.com"
  resource_group_name = azurerm_resource_group.example.name
}

module "front_door" {
  source = "../../"

  resource_group_name      = azurerm_resource_group.example.name
  profile_name             = "afd-complete-001"
  sku_name                 = "Premium_AzureFrontDoor"
  response_timeout_seconds = 180

  endpoints = {
    "ep-web"    = {}
    "ep-api"    = {}
    "ep-static" = {}
  }

  origin_groups = {
    "og-web" = {
      health_probe = {
        interval_in_seconds = 30
        path                = "/healthz"
        protocol            = "Https"
        request_type        = "GET"
      }
      load_balancing = {
        additional_latency_in_milliseconds = 50
        sample_size                        = 4
        successful_samples_required        = 2
      }
    }
    "og-api" = {
      session_affinity_enabled = true
      health_probe = {
        interval_in_seconds = 30
        path                = "/api/health"
        protocol            = "Https"
        request_type        = "GET"
      }
    }
    "og-static" = {
      health_probe = {
        path     = "/"
        protocol = "Https"
      }
    }
  }

  origins = {
    "origin-web-eastus" = {
      origin_group_name = "og-web"
      host_name         = "webapp-eastus.azurewebsites.net"
      priority          = 1
      weight            = 1000
    }
    "origin-web-westus" = {
      origin_group_name = "og-web"
      host_name         = "webapp-westus.azurewebsites.net"
      priority          = 2
      weight            = 1000
    }
    "origin-api" = {
      origin_group_name = "og-api"
      host_name         = "api-prod.azurewebsites.net"
    }
    "origin-static" = {
      origin_group_name = "og-static"
      host_name         = "mystatic.blob.core.windows.net"
      origin_host_header = "mystatic.blob.core.windows.net"
    }
  }

  custom_domains = {
    "www-example-com" = {
      host_name   = "www.example.com"
      dns_zone_id = azurerm_dns_zone.example.id
      tls = {
        certificate_type    = "ManagedCertificate"
        minimum_tls_version = "TLS12"
      }
    }
    "api-example-com" = {
      host_name   = "api.example.com"
      dns_zone_id = azurerm_dns_zone.example.id
    }
  }

  routes = {
    "rt-web" = {
      endpoint_name        = "ep-web"
      origin_group_name    = "og-web"
      patterns_to_match    = ["/*"]
      custom_domain_names  = ["www-example-com"]
      rule_set_names       = ["SecurityHeaders", "CacheOptimization"]

      cache = {
        query_string_caching_behavior = "UseQueryString"
        compression_enabled           = true
        content_types_to_compress = [
          "text/html", "text/css", "text/javascript",
          "application/javascript", "application/json",
          "application/xml", "image/svg+xml"
        ]
      }
    }
    "rt-api" = {
      endpoint_name          = "ep-api"
      origin_group_name      = "og-api"
      patterns_to_match      = ["/api/*"]
      custom_domain_names    = ["api-example-com"]
      forwarding_protocol    = "HttpsOnly"
      https_redirect_enabled = true
      rule_set_names         = ["SecurityHeaders"]
    }
    "rt-static" = {
      endpoint_name     = "ep-static"
      origin_group_name = "og-static"
      patterns_to_match = ["/static/*", "/assets/*"]

      cache = {
        query_string_caching_behavior = "IgnoreQueryString"
        compression_enabled           = true
        content_types_to_compress = [
          "text/css", "application/javascript",
          "image/svg+xml", "application/json"
        ]
      }
    }
  }

  rule_sets = {
    "SecurityHeaders" = {
      rules = {
        "AddSecurityHeaders" = {
          order = 1
          actions = {
            response_header_action = [
              { header_action = "Overwrite", header_name = "X-Content-Type-Options", value = "nosniff" },
              { header_action = "Overwrite", header_name = "X-Frame-Options", value = "SAMEORIGIN" },
              { header_action = "Overwrite", header_name = "Strict-Transport-Security", value = "max-age=31536000; includeSubDomains; preload" },
              { header_action = "Overwrite", header_name = "X-XSS-Protection", value = "1; mode=block" },
              { header_action = "Overwrite", header_name = "Referrer-Policy", value = "strict-origin-when-cross-origin" }
            ]
          }
        }
      }
    }
    "CacheOptimization" = {
      rules = {
        "CacheStaticAssets" = {
          order = 1
          conditions = {
            request_uri_conditions = [{
              operator     = "Contains"
              match_values = [".js", ".css", ".png", ".jpg", ".gif", ".woff2"]
            }]
          }
          actions = {
            response_header_action = [
              { header_action = "Overwrite", header_name = "Cache-Control", value = "public, max-age=31536000, immutable" }
            ]
          }
        }
        "NoCacheAPI" = {
          order = 2
          conditions = {
            request_uri_conditions = [{
              operator     = "BeginsWith"
              match_values = ["/api/"]
            }]
          }
          actions = {
            response_header_action = [
              { header_action = "Overwrite", header_name = "Cache-Control", value = "no-store, no-cache, must-revalidate" }
            ]
          }
        }
      }
    }
  }

  waf_policies = {
    "wafpolicyprod" = {
      mode    = "Prevention"
      enabled = true

      custom_rules = [
        {
          name     = "RateLimitRule"
          priority = 100
          type     = "RateLimitRule"
          action   = "Block"

          match_conditions = [{
            match_variable = "RemoteAddr"
            operator       = "IPMatch"
            match_values   = ["0.0.0.0/0"]
          }]

          rate_limit_duration_in_minutes = 1
          rate_limit_threshold           = 1000
        },
        {
          name     = "BlockBadBots"
          priority = 200
          type     = "MatchRule"
          action   = "Block"

          match_conditions = [{
            match_variable = "RequestHeader"
            selector       = "User-Agent"
            operator       = "Contains"
            match_values   = ["BadBot", "EvilCrawler"]
            transforms     = ["Lowercase"]
          }]
        }
      ]

      managed_rules = [
        {
          type    = "Microsoft_DefaultRuleSet"
          version = "2.1"
          action  = "Block"
        },
        {
          type    = "Microsoft_BotManagerRuleSet"
          version = "1.0"
          action  = "Block"
        }
      ]
    }
  }

  security_policies = {
    "sp-waf-web" = {
      waf_policy_name = "wafpolicyprod"
      endpoint_names  = ["ep-web", "ep-api"]
    }
  }

  tags = {
    Environment = "production"
    Project     = "web-platform"
    CostCenter  = "CDN-001"
  }
}

output "profile_id" {
  value = module.front_door.profile_id
}

output "endpoint_host_names" {
  value = module.front_door.endpoint_host_names
}

output "custom_domain_validation_tokens" {
  value = module.front_door.custom_domain_validation_tokens
}

output "waf_policy_ids" {
  value = module.front_door.waf_policy_ids
}
