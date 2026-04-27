provider "aws" {
  region = "us-east-1"
}
resource "aws_vpc" "test-vpc" {
  tags = {
    Name = "test-vpc"
  }
  cidr_block = "10.0.0.0/24"
}

resource "aws_subnet" "test-subnet" {
  vpc_id = aws_vpc.test-vpc.id
}
#coming soon ...