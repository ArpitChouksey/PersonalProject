output "vpc_id" {

  value = module.networking.vpc_id

}

output "app_subnet" {

  value = module.networking.app_subnet_id

}

output "db_subnet" {

  value = module.networking.db_subnet_id

}

output "windows_sg" {

  value = module.security_groups.windows_security_group_id

}

output "linux_sg" {

  value = module.security_groups.linux_security_group_id

}

output "database_sg" {

  value = module.security_groups.database_security_group_id

}


output "windows_private_ip" {
  value = module.windows.private_ip
}

output "linux_private_ip" {
  value = module.linux.private_ip
}

output "vpn_endpoint_id" {
  value = module.vpn.vpn_endpoint_id
}

output "vpn_endpoint_arn" {
  value = module.vpn.vpn_endpoint_arn
}

output "vpn_dns_name" {
  value = module.vpn.vpn_dns_name
}
