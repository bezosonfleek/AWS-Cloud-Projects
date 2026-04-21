provider "aws" {
    region = "us-east-1"
}

resource "aws_instance" "test-instnce" {
    ami           = "ami-05024c2628f651b80"
    instance_type = "t3.micro"
    
    tags = {
        Name = "test-again"
    }
}
