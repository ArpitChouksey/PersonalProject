############################################
# EXISTING private route → EXISTING NAT
# (IMPORT ONLY – NO CREATION)
############################################
resource "aws_route" "private_nat" {
  route_table_id         = var.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.nat_gateway_id
}

