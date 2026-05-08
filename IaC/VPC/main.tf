provider "aws" {
  region = "us-east-1"
 }

variable "subnet_prefix" {
  description = "cidr block for public subnet"
  #default = "10.0.0.100/28"
  #type = string 
}

resource "aws_vpc" "test-vpc" {
  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "test-vpc"
  }
}

resource "aws_subnet" "public-subnet-test" {
  vpc_id = aws_vpc.test-vpc.id
  cidr_block = var.subnet_prefix[0].cidr_block # initially cidr_block = "10.0.0.0/25"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true 
  tags = {
    Name = var.subnet_prefix[0].name
  }
}

resource "aws_subnet" "private-subnet-test" {
  vpc_id = aws_vpc.test-vpc.id
  cidr_block = var.subnet_prefix[1].cidr_block 
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true 
  tags = {
    Name = var.subnet_prefix[1].name
  }
}

resource "aws_security_group" "public-sg-test" {
  name = "public-sg-test"
  vpc_id = aws_vpc.test-vpc.id
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #tighten security; my ip/32
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress{
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# *Consider adding network interface

resource "aws_internet_gateway" "ig-test" {
  vpc_id = aws_vpc.test-vpc.id
}

resource "aws_route_table" "rt-public-test" {
 vpc_id = aws_vpc.test-vpc.id
 tags = {
   Name = "rt-public-test"
 }
}

resource "aws_route" "public-route" {
  route_table_id = aws_route_table.rt-public-test.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.ig-test.id
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id = aws_subnet.public-subnet-test.id 
  route_table_id = aws_route_table.rt-public-test.id
}

resource "aws_instance" "ec2-test" {
  tags = {
    Name = "ec2-test"
  }

  ami = "ami-091138d0f0d41ff90"
  instance_type = "t3.micro"
  subnet_id = aws_subnet.public-subnet-test.id
  vpc_security_group_ids = [aws_security_group.public-sg-test.id] 

  user_data = <<-EOF
              #!/bin/bash
              apt-get install -y nginx
              systemctl start nginx
              systemctl enable nginx
              echo "<h1>Congrats! Terraform knowledge improved!</h1>" > /var/www/html/index.html
              EOF
}

output "server_public_ip" {
  value = aws_instance.ec2-test.public_ip
}
#optionally hard code availability zone in ec2 and subnet to avoid randomization which causes communication hurdles
# note: -target flag can be used to target a single resource