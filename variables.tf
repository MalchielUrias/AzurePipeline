variable "subscription_id" {
  type = string
  default = ""
}

variable "client_id" {
  type = string
  default = ""
}

variable "client_secret" {
  type = string
  default = ""
  sensitive = true
}

variable "tenant_id" {
  type = string
  default = ""
}

# Declaring local variables to be used within main.tf
locals {
  resource_group = "application_grp"
  location = "North Europe"
}