provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "rg-front-door-basic"
  location = "East US"
}

module "front_door" {
  source = "../../"

  resource_group_name = azurerm_resource_group.example.name
  profile_name        = "afd-basic-001"
  sku_name            = "Standard_AzureFrontDoor"

  endpoints = {
    "ep-web" = {}
  }

  origin_groups = {
    "og-web" = {
      health_probe = {
        path     = "/"
        protocol = "Https"
      }
    }
  }

  origins = {
    "origin-webapp" = {
      origin_group_name = "og-web"
      host_name         = "mywebapp.azurewebsites.net"
    }
  }

  routes = {
    "rt-default" = {
      endpoint_name     = "ep-web"
      origin_group_name = "og-web"
      patterns_to_match = ["/*"]
    }
  }

  tags = {
    Environment = "development"
  }
}

output "profile_id" {
  value = module.front_door.profile_id
}

output "endpoint_host_names" {
  value = module.front_door.endpoint_host_names
}
