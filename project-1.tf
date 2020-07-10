provider "aws" {
  region = "us-east-2"
}



data "aws_ami" "latest_amazon_linux" {
  owners      = ["099720109477"]
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}

#--------------------------------------------------------------
resource "aws_instance" "web_server_1" {
  ami                    = data.aws_ami.latest_amazon_linux.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = "andrewweckman-us-ohio"
  tags = {
    Name = "WebServer"
  }
}

resource "aws_instance" "web_server_2" {
  ami                    = data.aws_ami.latest_amazon_linux.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = "andrewweckman-us-ohio"
  tags = {
    Name = "WebServer"
  }
}


resource "aws_security_group" "web" {
  name = "Dynamic Security Group"

  dynamic "ingress" {
    for_each = ["80", "443", "22", "8080"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "Dynamic SecurityGroup"
    Owner = "Denis Astahov"
  }
}


resource "aws_elb_attachment" "web" {
  elb      = aws_elb.web.id
  instance = aws_instance.web_server_1.id
}

resource "aws_elb_attachment" "web_1" {
  elb      = aws_elb.web.id
  instance = aws_instance.web_server_2.id
}

resource "aws_elb" "web" {
  name               = "WebServer-HA-ELB"
  availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]
  security_groups    = [aws_security_group.web.id]
  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = 80
    instance_protocol = "http"
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 10
  }
  tags = {
    Name = "WebServer-Highly-Available-ELB"
  }
}




#--------------------------------------------------
output "web_loadbalancer_url" {
  value = aws_elb.web.dns_name
}
