##############################################
# Windows
##############################################

output "windows_security_group_id" {
  value = aws_security_group.windows.id
}

##############################################
# Linux
##############################################

output "linux_security_group_id" {
  value = aws_security_group.linux.id
}

##############################################
# Database
##############################################

output "database_security_group_id" {
  value = aws_security_group.database.id
}
