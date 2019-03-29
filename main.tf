provider "aws" {
  region = "eu-west-1"
  profile = "sandbox"
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "ssh-tunnel" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.ssh-tunnel.id}"
}

resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.ssh-tunnel.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

resource "aws_subnet" "ssh-tunnel" {
  vpc_id                  = "${aws_vpc.ssh-tunnel.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
}

resource "aws_subnet" "ssh-tunnel2" {
  vpc_id                  = "${aws_vpc.ssh-tunnel.id}"
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone = "${data.aws_availability_zones.available.names[1]}"
}

data "http" "workstation-external-ip" {
  url = "http://ipv4.icanhazip.com"
}

locals {
  workstation-external-cidr = "${chomp(data.http.workstation-external-ip.body)}/32"
}

resource "aws_neptune_subnet_group" "example" {
  name       = "main"
  subnet_ids = ["${aws_subnet.ssh-tunnel.id}", "${aws_subnet.ssh-tunnel2.id}"]

  tags = {
    Name = "My neptune subnet group"
  }
}

resource "aws_neptune_cluster" "example" {
  cluster_identifier                  = "${var.neptune_name}"
  engine                              = "neptune"
  skip_final_snapshot                 = true
  iam_database_authentication_enabled = false
  apply_immediately                   = true
  vpc_security_group_ids              = [ "${aws_security_group.neptune_example.id}" ]
  neptune_subnet_group_name           = "${aws_neptune_subnet_group.example.name}"
}

resource "aws_neptune_cluster_instance" "example" {
  count              = "${var.neptune_count}"
  cluster_identifier = "${aws_neptune_cluster.example.id}"
  engine             = "neptune"
  instance_class     = "db.r4.large"
  apply_immediately  = true
  neptune_subnet_group_name = "${aws_neptune_subnet_group.example.name}"
}

resource "aws_key_pair" "auth" {
  public_key = "${file(var.public_key_path)}"
}

data "aws_ami" "bastion-ami" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_instance" "neptune-ec2-connector" {
  connection {
    user = "ec2-user"
    agent = "false"
    private_key = "${file(var.private_key_path)}"
  }

  instance_type = "t2.micro"
  ami = "${data.aws_ami.bastion-ami.id}"
  key_name = "${aws_key_pair.auth.id}"
  vpc_security_group_ids = ["${aws_security_group.neptune_example.id}"]
  subnet_id = "${aws_subnet.ssh-tunnel.id}"
}

resource "aws_security_group" "neptune_example" {
  name        = "${var.neptune_sg_name}"
  description = "Bastion"
  vpc_id      = "${aws_vpc.ssh-tunnel.id}"

  ingress {
    from_port   = 8182
    to_port     = 8182
    protocol    = "tcp"
    self = true
  }


  # Allow SSH from anywhere...
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${local.workstation-external-cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}