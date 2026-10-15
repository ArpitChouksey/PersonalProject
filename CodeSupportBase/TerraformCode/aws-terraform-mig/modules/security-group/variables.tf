variable "vpc_id" {
  type = string
}

variable "security_groups" {
  type = map(object({
    name        = string
    description = string

    ingress = list(object({
      description     = string
      from_port       = number
      to_port         = number
      protocol        = string
      cidr_blocks     = optional(list(string), [])
      security_groups = optional(list(string), [])
    }))

    egress = list(object({
      description = string
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = optional(list(string), [])
    }))
  }))
}
