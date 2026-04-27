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
  ingress {
  allow = 22
  }

#coming soon ...