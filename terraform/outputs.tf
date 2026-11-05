output "vpc_id" {
  value       = aws_vpc.main.id
  description = "ID de la VPC creada."
}

output "public_subnet_id" {
  value       = aws_subnet.public.id
  description = "ID de la subred pública."
}

output "private_subnet_id" {
  value       = aws_subnet.private.id
  description = "ID de la subred privada."
}
output "nat_gateway_id" {
  value       = aws_nat_gateway.nat.id
  description = "ID del NAT Gateway para la salida privada a internet."
}