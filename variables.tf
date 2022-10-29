variable "prefix" {
  type        = string
  description = "The prefix which should be used for all resources in this module"
  default     = "aaa"
  validation {
    condition     = length(var.prefix) < 4
    error_message = "prefix must be less than 4 characters long"
  }
}

variable "env" {
  type        = string
  description = "The environement for the resoruce"
  default     = "dev"
  validation {
    condition     = length(var.env) < 4
    error_message = "env value must be less than 4 characters long"
  }
}

variable "machine_number" {
  type        = string
  description = "unique machine number to be a suffix to the overall machine name and resource group"
}

variable "allowed_list_ips" {
  type        = string
  description = "The IP addresses that will be allowed to talk to the workstation controlled by the NSG; simple comma-delimited list"
  default     = null
}

variable "location" {
  type        = string
  description = "The Azure Region in which all resources in this module"
  default     = "eastus2"
}

variable "users_group" {
  type        = string
  description = "AD Group group that will be users of the dsvm"
}

variable "size" {
  type        = string
  description = "The VM Size"
  default     = "Standard_B1s"
}

variable "username" {
  type    = string
  default = "adminuser"
}

variable "timezone" {
  type        = string
  description = "timezone used for VM as well as auto shutdown"
}

# Standard Tags
variable "tags" {
  default     = {}
  description = "The generic tags for this project that go on all resources"
  type        = map(string)
}

variable "state_container_name" {
  default     = ""
  description = "Used by the boostrap shell script but provide here incase it is needed, in the output by default"
  type        = string
}

variable "state_key" {
  default     = ""
  description = "Used by the bootstrap shell script but provided here incase it is needed, in the output by default"
  type        = string
}

