variable "vpc_id" {
  type = string
}

variable "internet_gateway_id" {
  type = string
}

variable "subnet_ids" {
  type = map(string)
}

variable "route_tables" {
  type = map(object({
    name = string

    routes = map(object({
      destination_cidr_block = string
      gateway_id             = optional(string)
    }))

    subnet_names = list(string)
  }))
}
