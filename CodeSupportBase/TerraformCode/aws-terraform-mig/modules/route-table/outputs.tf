output "route_table_ids" {
  value = {
    for key, rt in aws_route_table.this :
    key => rt.id
  }
}
