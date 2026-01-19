provider "aws" {
  region = var.region
}

# Security Group
resource "aws_security_group" "gamma_sg" {
  name        = "gamma-analytics-sg"
  description = "Project Gamma icin guvenlik kurallari"

  # SSH 
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Daha güvenli olsun istersen buraya kendi IP'ni yazabilirsin.
  }

  # HTTP (to monitor Kibana on Nginx))
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Logstash Ingestion 
  ingress {
    from_port   = 5044
    to_port     = 5044
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 
resource "aws_instance" "app_server" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name # AWS'de oluşturduğun .pem anahtarının adı
  
  # Security Group connection
  vpc_security_group_ids = [aws_security_group.gamma_sg.id]

  # Script that runs when server is starting
  user_data = file("user_data.sh")

  tags = {
    Name = "Gamma-RealTime-Analytics"
  }
}