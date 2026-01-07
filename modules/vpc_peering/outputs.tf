# VPC Peering Module: 출력값

output "peering_connection_id" {
  description = "VPC Peering Connection ID"
  value       = aws_vpc_peering_connection.main.id
}

output "peering_connection_status" {
  description = "VPC Peering Connection 상태"
  value       = aws_vpc_peering_connection.main.accept_status
}

output "requester_routes_created" {
  description = "Requester VPC에 생성된 라우팅 개수"
  value       = length(aws_route.requester_to_accepter)
}

output "accepter_routes_created" {
  description = "Accepter VPC에 생성된 라우팅 개수"
  value       = length(aws_route.accepter_to_requester)
}
