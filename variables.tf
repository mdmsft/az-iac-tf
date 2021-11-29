variable "project" {
  type    = string
  default = "contoso"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "instance" {
  type    = string
  default = "hub"
}

variable "virtual_network_address_space" {
  type    = string
  default = "172.17.0.0/16"
}

variable "jumpbox_admin_username" {
  type    = string
  default = "azure"
}

variable "jumpbox_admin_password" {
  type      = string
  sensitive = true
}
