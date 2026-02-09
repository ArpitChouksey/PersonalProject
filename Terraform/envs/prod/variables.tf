variable "vpc_cidr" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "subnets" {
  type = map(object({
    cidr   = string
    az     = string
    public = bool
  }))
}

variable "igw_name" {
  type = string
}

