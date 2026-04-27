provider "aws" {
  region = "us-east-1"
 }

resource "aws_vpc" "test-vpc" {
  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "test-vpc"
  }
}

resource "aws_subnet" "public-subnet-test" {
  vpc_id = aws_vpc.test-vpc.id
  cidr_block = "10.0.0.0/25"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true 
}

resource "aws_security_group" "public-sg-test" {
  name = "public-sg-test"
  vpc_id = aws_vpc.test-vpc.id
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #tighten security; my ip/32
  }
  egress{
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

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

  ami = "ami-0ec10929233384c7f"
  instance_type = "t3.micro"
  subnet_id = aws_subnet.public-subnet-test.id
  vpc_security_group_ids = [aws_security_group.public-sg-test.id]
}
#to be completed - add private subnet, elastic ip (try to print it out)