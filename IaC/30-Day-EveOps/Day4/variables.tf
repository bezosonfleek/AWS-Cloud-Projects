variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 80
}

variable "instance_type" {
    description = "EC2 instance type"
    type = string
    default = "t3.micro"
}

variable "region" {
    description = "AWS region"
    type = string
    default = "us-east-1"
}

variable "min_size"{
    default = 2
}

variable "max_size"{
    default = 5
}