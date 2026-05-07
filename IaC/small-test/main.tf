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

resource "aws_s3_bucket" "geoffrey-terraform-state" {
    bucket = "geoffrey-terraform-state"
}
resource "aws_dynamodb_table" "terraform-lock-table" {
    name           = "terraform-lock-table"
    billing_mode   = "PAY_PER_REQUEST"
    hash_key       = "LockID"

    attribute {
        name = "LockID"
        type = "S"
    }
}

terraform {
  backend "s3" {
    bucket         = "geoffrey-terraform-state"
    key            = "network/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-table" # This enables the locking!
    encrypt        = true
  }
}