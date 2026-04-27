provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "test-vpc" {
  cidr_block = 10.0.0.0/24
  tags = {
    Name = test-vpc
  }
}

resource "aws_subnet" "public-subnet-test" {
  vpc.id = aws_vpc.test-vpc.id
}

resource "aws_subnet" "public-subnet-test" {
  vpc.id = aws_vpc.test-vpc.id
}

resource "aws_security_group" "private-sg-test" {
  vpc_id = aws_vpc.test-vpc.id
  ingress {
  from_port = 22
  to_port = 22
  protocol = tcp
  source = 0.0.0.0 #tighten security
  }
  egress{
  }

#coming soon ...