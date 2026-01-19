variable "region" {
  description = "AWS Region"
  default     = "us-west-2"
}

variable "instance_type" {
  description = "Server Type"
  default     = "t3.large" # required for ELK Stack 
}

variable "key_name" {
  description = "SSH Key Pair Name"
  type        = string
}