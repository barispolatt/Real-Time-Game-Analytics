output "server_public_ip" {
  description = "Server Public IP Address"
  value       = aws_instance.app_server.public_ip
}

output "kibana_url" {
  description = "Kibana Access Link"
  value       = "http://${aws_instance.app_server.public_ip}"
}