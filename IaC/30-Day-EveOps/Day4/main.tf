provider "aws" {
  region = var.region
}

# Fetch latest Amazon Linux 2 AMI dynamically (DRY + production-ready)
data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

#Security Group for traffic
resource "aws_security_group" "instance_sg" {
  name        = "terraform-instance"
  description = "Allow HTTP traffic"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic (required for updates, installs, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
} 

# #Create EC2 instance  for running a simple web server
# resource "aws_instance" "web" {
#     # Use dynamic AMI instead of hardcoding
#     ami = data.aws_ami.amazon_linux.id
#     instance_type = var.instance_type

#     vpc_security_group_ids = [aws_security_group.instance_sg.id]

#     # Simple web server using httpd
#     user_data = <<-EOF
#                 #!/bin/bash
#                 yum update -y
#                 yum install -y httpd

#                 echo "Hello, Terraform Day 4!" > /var/www/html/index.html
                
#                 systemctl start httpd
#                 systemctl enable httpd
#                 EOF

#     tags = {
#         Name = "Terraform-Day4-Instance"
#     }
# }

# # Output public IP for access
# output "public_ip" {
#   value = aws_instance.web.public_ip
# }

#Get default VPC to launch instances into (production-ready, avoids hardcoding)
data "aws_vpc" "default" {
  default = true
}

#Get subnets in default VPC (production-ready, avoids hardcoding)
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "terraform-alb-sg"
  description = "Allow HTTP traffic to ALB"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "web_alb" {
  name               = "terraform-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids

  tags = {
    Name = "Terraform-Web-ALB"
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = var.server_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
   }
}

resource "aws_lb_target_group" "web_tg" {
  name     = "terraform-web-tg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_launch_template" "web_lt" {
  name_prefix   = "terraform-web-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd

              echo "Hello, Terraform Auto Scaling!" > /var/www/html/index.html
              
              systemctl start httpd
              systemctl enable httpd
              EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "Terraform-Web-ASG-Instance"
    }
  }
}

resource "aws_autoscaling_group" "web_asg" {
  name_prefix           = "terraform-web-asg-"
  vpc_zone_identifier   = data.aws_subnets.default.ids
  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }
  min_size              = var.min_size
  max_size              = var.max_size
  desired_capacity      = 2

  target_group_arns = [aws_lb_target_group.web_tg.arn]

  health_check_type = "ELB"

  tag {
    key                 = "Name"
    value               = "Terraform-Web-ASG-Instance"
    propagate_at_launch = true
  }
}

output "alb_dns_name" {
  value = aws_lb.web_alb.dns_name
}