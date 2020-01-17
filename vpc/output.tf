output "id" {
  value = aws_vpc.default.id
}

output "security_group_ids" {
  value = aws_security_group.default.*.id
}

output "route_table_id" {
  value = aws_route_table.default.id
}
