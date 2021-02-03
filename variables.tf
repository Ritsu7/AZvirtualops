variable "virtualOps_rg" {
  type = string
}

variable "virtualOps_location" {
  type = string
}

variable "resource_prefix" {
  type = string
}

variable "virtualOps_vm_name" {
  type = string
}

variable "vnet_address_space" {
  type = string
}

variable "virtualops_subnets" {
  type = map
}

variable "terraform_script_version" {
  type = string
}
