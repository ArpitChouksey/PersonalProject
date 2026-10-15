variable "name" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}


variable "enable_dns_support" {
  type = bool
}

variable "enable_dns_hostnames" {
  type = bool
}
