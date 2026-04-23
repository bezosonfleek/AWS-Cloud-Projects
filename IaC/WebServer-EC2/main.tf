provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "tf-test" {
  ami = "ami-0ec10929233384c7f"  #ubuntu instance
  instance_type = "t3.micro"
  vpc_security_group_ids = ["xxxxxxxxxxx"]
  subnet_id = "xxxxxxxxxxxx"
user_data = <<-EOF
             #!/bin/bash
             apt install -y nginx
             systemctl start nginx
             systemctl enable nginx
             echo '<h1>Terraform Master on the Board!</h1>' > /var/www/html/index.html
             EOF
  tags = {
    Name = "tf-test"
  }
}

resource "aws_eip" "sakora-eip-1" {
  domain = "vpc"
}
resource "aws_eip_association" "eip_assoc" {
  instance_id = aws_instance.tf-test.id
  allocation_id = aws_eip.sakora-eip-1.id
}