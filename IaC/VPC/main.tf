provider "aws" {
  region = "us-east-1"
}
<<<<<<< HEAD
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
=======

resource "aws_vpc" "test-vpc" {
  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "test-vpc"
  }
}

resource "aws_subnet" "public-subnet-test" {
  vpc.id = aws_vpc.test-vpc.id
  cidr_block = "10.0.0.0/25"
  availability_zone = "us-east-1a"
  #map_public_ip_on_launch = true 
}

resource "aws_security_group" "private-sg-test" {
  name = "private-sg-test"
  vpc_id = aws_vpc.test-vpc.id
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #tighten security
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
}

resource "aws_route" "public default" {
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

  ami = "ami-0c7217cdde317cfec"
  instance_type = "t3.micro"
  subnet_id = aws_subnet.public-subnet-test.id
  vpc_security_group_ids = [aws_security_group.private-sg-test.id]
}
#to be completed - add private subnet, elasticbs
>>>>>>> 753d0e4c64f3167eb457c76b078bee91c56c0091
