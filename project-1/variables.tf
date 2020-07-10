variable "region" {
  description = "Enter AWS Region"
  type        = string
  default     = "us-east-2"
}


variable "instance_type" {
  description = "Instance Type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Security key"
  default     = "andrewweckman-us-ohio"
}

variable "allow_ports" {
  description = "List of Ports to open"
  type        = list
  default     = ["80", "443", "22", "8080"]
}
