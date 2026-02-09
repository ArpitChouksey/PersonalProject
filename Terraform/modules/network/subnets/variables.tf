variable "vpc_id" {
  type = string
}

variable "subnets" {
  type = map(object({
    cidr   = string
    az     = string
    public = bool
  }))
}
