output "vpc_id" {
  description = "ID створеної VPC"
  value       = aws_vpc.main.id
}

output "public_subnets" {
  description = "Список ID публічних підмереж"
  value       = aws_subnet.public[*].id
}

output "private_subnets" {
  description = "Список ID приватних підмереж"
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "ID Internet Gateway"
  value       = aws_internet_gateway.igw.id
}

output "vpc_cidr_block" {
  description = "CIDR блок VPC"
  value       = aws_vpc.main.cidr_block
}

output "nat_instance_id" {
  description = "ID of the NAT EC2 instance"
  value       = aws_instance.nat_instance.id
}
