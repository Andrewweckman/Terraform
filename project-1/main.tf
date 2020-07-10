provider "aws" {
  region = var.region
}

data "aws_availability_zones" "working" {}


data "aws_ami" "latest_ubuntu" {
  owners      = ["099720109477"]
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}


resource "aws_eip" "my_static_ip" {
  instance = aws_elb.web.id
  tags = {
    Name = "LoadBalancer_Elastic_ip"
  }
}

resource "aws_instance" "web_server_1" {
  ami                    = data.aws_ami.latest_ubuntu.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = var.key_name
  tags = {
    Name = "WebServer-1"
  }
}

resource "aws_instance" "web_server_2" {
  ami                    = data.aws_ami.latest_ubuntu.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = var.key_name
  tags = {
    Name = "WebServer-2"
  }
}


resource "aws_security_group" "web" {
  name = "Dynamic Security Group"

  dynamic "ingress" {
    for_each = var.allow_ports
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
    Name = "Dynamic SecurityGroup"
  }
}


resource "aws_elb" "web" {
  name               = "WebServer-HA-ELB"
  availability_zones = data.aws_availability_zones.working.names
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


resource "aws_elb_attachment" "web" {
  elb      = aws_elb.web.id
  instance = aws_instance.web_server_1.id
}

resource "aws_elb_attachment" "web_1" {
  elb      = aws_elb.web.id
  instance = aws_instance.web_server_2.id
}
