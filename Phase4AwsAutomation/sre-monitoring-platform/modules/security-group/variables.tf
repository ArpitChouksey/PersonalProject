variable "vpc_id" {
  type = string
}

variable "sg_name" {
  type = string
}

variable "sg_description" {
  type = string
}

variable "allowed_ip" {
  type = string
}

variable "allowed_ports" {
  type = list(number)
}
