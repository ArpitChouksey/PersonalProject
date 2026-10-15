resource "aws_route_table" "this" {
  for_each = var.route_tables

  vpc_id = var.vpc_id

  tags = {
    Name = each.value.name
  }
}

resource "aws_route" "this" {
  for_each = {
    for item in flatten([
      for rt_key, rt in var.route_tables : [
        for route_key, route in rt.routes : {
          key                    = "${rt_key}-${route_key}"
          route_table_key        = rt_key
          destination_cidr_block = route.destination_cidr_block
          gateway_id             = route.gateway_id
        }
      ]
    ]) : item.key => item
  }

  route_table_id         = aws_route_table.this[each.value.route_table_key].id
  destination_cidr_block = each.value.destination_cidr_block

  gateway_id = each.value.gateway_id
}

resource "aws_route_table_association" "this" {
  for_each = {
    for item in flatten([
      for rt_key, rt in var.route_tables : [
        for subnet_name in rt.subnet_names : {
          key         = "${rt_key}-${subnet_name}"
          rt_key      = rt_key
          subnet_name = subnet_name
        }
      ]
    ]) : item.key => item
  }

  route_table_id = aws_route_table.this[each.value.rt_key].id
  subnet_id      = var.subnet_ids[each.value.subnet_name]
}
