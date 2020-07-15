provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}

resource "aws_subnet" "public-a" {
  vpc_id     = aws_vpc.default.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "public-a-tf"
  }
}

resource "aws_subnet" "public-b" {
  vpc_id     = aws_vpc.default.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "public-b-tf"
  }
}

resource "aws_subnet" "private-a" {
  vpc_id     = aws_vpc.default.id
  cidr_block = "10.0.3.0/24"


  tags = {
    Name = "private-a-tf"
  }
}

resource "aws_subnet" "private-b" {
  vpc_id     = aws_vpc.default.id
  cidr_block = "10.0.4.0/24"

  tags = {
    Name = "private-b-tf"
  }
}

resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "terraform"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "igw-tf"
  }
}

resource "aws_route_table" "gw" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "internet-tf"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public-a.id
  route_table_id = aws_route_table.gw.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public-b.id
  route_table_id = aws_route_table.gw.id
}

resource "tls_private_key" "yann_key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "ec2-key-tf"
  public_key = tls_private_key.yann_key_pair.public_key_openssh
}

output "private-key" {
  value = tls_private_key.yann_key_pair.private_key_pem
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public-a.id
  key_name      = aws_key_pair.generated_key.id
  associate_public_ip_address = true
  user_data = data.template_file.ami_name.rendered
  vpc_security_group_ids = ["${aws_security_group.allow_tls.id}"] 

  tags = {
    Name = "HelloWorld"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical 
}

output "private-key-2" {
  value = tls_private_key.yann_key_pair.private_key_pem
}

output "ami-value" {
  value = data.aws_ami.ubuntu.image_id
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tf"
  }
}

data "template_file" "ami_name" {
  template = file("${path.module}/postinstall.sh")
  vars = {
    consul_address = data.aws_ami.ubuntu.name
  }
}

output "public_ip" {
  value = tls_private_key.yann_key_pair.private_key_pem
}
  
output "ami-value-2" {
  value = data.aws_ami.ubuntu.image_id
}

output "public-ip" {
  value = aws_instance.web.public_ip
}
