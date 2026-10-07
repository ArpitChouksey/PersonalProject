output "landing_zone_id" {
  value = aws_controltower_landing_zone.this.id
}

output "landing_zone_version" {
  value = var.landing_zone_version
}
