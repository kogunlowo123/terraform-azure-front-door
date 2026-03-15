resource "azurerm_resource_group" "test" {
  name     = "rg-frontdoor-test"
  location = "eastus2"
}

module "test" {
  source = "../"

  resource_group_name = azurerm_resource_group.test.name
  profile_name        = "afd-test-profile"
  sku_name            = "Standard_AzureFrontDoor"

  endpoints = {
    web = {
      enabled = true
    }
  }

  origin_groups = {
    webapp = {
      health_probe = {
        interval_in_seconds = 100
        path                = "/healthz"
        protocol            = "Https"
        request_type        = "HEAD"
      }
      load_balancing = {
        sample_size                 = 4
        successful_samples_required = 3
      }
    }
  }

  origins = {
    webapp-primary = {
      origin_group_name = "webapp"
      host_name         = "webapp-test.azurewebsites.net"
      https_port        = 443
      priority          = 1
      weight            = 1000
    }
  }

  routes = {
    default = {
      endpoint_name     = "web"
      origin_group_name = "webapp"
      origin_names      = ["webapp-primary"]
      patterns_to_match = ["/*"]
    }
  }

  tags = {
    Environment = "test"
    ManagedBy   = "terraform"
  }
}
