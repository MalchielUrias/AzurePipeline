variable "subscription_id" {
  type = string
  default = "8b2389b0-c40e-4b4f-b75e-26b8bf68f816"
}

variable "client_id" {
  type = string
  default = "833de94c-e2fd-4c54-ab7f-4882579007c1"
}

variable "client_secret" {
  type = string
  default = "bY18Q~czfqqf18HkAIc~CxmqL1EMWVXN2Tzk2bKJ"
  sensitive = true
}

variable "tenant_id" {
  type = string
  default = "7e3bc85c-3c7b-4ea4-93d9-ae13419ae8e6"
}

# Declaring local variables to be used within main.tf
locals {
  resource_group = "application_grp"
  location = "North Europe"
}