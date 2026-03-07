provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "rg-front-door-advanced"
  location = "East US"
}

module "front_door" {
  source = "../../"

  resource_group_name = azurerm_resource_group.example.name
  profile_name        = "afd-advanced-001"
  sku_name            = "Standard_AzureFrontDoor"

  endpoints = {
    "ep-web" = {}
    "ep-api" = {}
  }

  origin_groups = {
    "og-web" = {
      health_probe = {
        interval_in_seconds = 60
        path                = "/healthz"
        protocol            = "Https"
        request_type        = "GET"
      }
      load_balancing = {
        additional_latency_in_milliseconds = 100
        sample_size                        = 4
        successful_samples_required        = 2
      }
    }
    "og-api" = {
      session_affinity_enabled = true
      health_probe = {
        path     = "/api/health"
        protocol = "Https"
      }
    }
  }

  origins = {
    "origin-web-primary" = {
      origin_group_name = "og-web"
      host_name         = "mywebapp-primary.azurewebsites.net"
      priority          = 1
      weight            = 1000
    }
    "origin-web-secondary" = {
      origin_group_name = "og-web"
      host_name         = "mywebapp-secondary.azurewebsites.net"
      priority          = 2
      weight            = 500
    }
    "origin-api" = {
      origin_group_name = "og-api"
      host_name         = "myapi.azurewebsites.net"
    }
  }

  routes = {
    "rt-web" = {
      endpoint_name     = "ep-web"
      origin_group_name = "og-web"
      patterns_to_match = ["/*"]

      cache = {
        query_string_caching_behavior = "UseQueryString"
        compression_enabled           = true
        content_types_to_compress = [
          "text/html",
          "text/css",
          "application/javascript",
          "application/json"
        ]
      }
    }
    "rt-api" = {
      endpoint_name          = "ep-api"
      origin_group_name      = "og-api"
      patterns_to_match      = ["/api/*"]
      forwarding_protocol    = "HttpsOnly"
      https_redirect_enabled = true
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
              { header_action = "Overwrite", header_name = "X-Frame-Options", value = "DENY" },
              { header_action = "Overwrite", header_name = "Strict-Transport-Security", value = "max-age=31536000; includeSubDomains" }
            ]
          }
        }
      }
    }
  }

  tags = {
    Environment = "staging"
    Project     = "web-platform"
  }
}

output "profile_id" {
  value = module.front_door.profile_id
}

output "endpoint_host_names" {
  value = module.front_door.endpoint_host_names
}
