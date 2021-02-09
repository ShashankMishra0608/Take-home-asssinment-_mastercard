###########
# Defaults
##########

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region     = "ap-south-1"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "test"
}


data "aws_availability_zones" "available" {
  state = "available"
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

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  owners = ["099720109477"] # Canonical
}

######
# VPC
######
resource "aws_vpc" "main" {
 cidr_block = "10.0.0.0/16"
 enable_dns_hostnames = var.enable_dns_hostnames
 enable_dns_support   = var.enable_dns_support

  tags = {
    Terraform = "true"
    Name      = "${var.name}_vpc"
  }
}

###################
# Internet Gateway
###################
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}_iGW"
  }

}

################
# Publiс routes
################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-public_routes"
  }

}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id

  timeouts {
    create = "5m"
  }
}

#################
# Private routes A
# There are as many routing tables as the number of NAT gateways
#################
resource "aws_route_table" "private_A" {
  count  = length(data.aws_availability_zones.available.names)
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}_private_routes_A"
  }
}

#################
# Private routes B
# There are as many routing tables as the number of NAT gateways
#################
resource "aws_route_table" "private_B" {
  count  = length(data.aws_availability_zones.available.names)
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}_private_routes_B"
  }
}

################
# Public subnet
################
resource "aws_subnet" "public" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}_public_subnets"
  }
}

#################
# Private subnet A
#################
resource "aws_subnet" "private_A" {
  count             = length(data.aws_availability_zones.available.names)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets_A[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.name}_private_subnets_A"
  }
}

#################
# Private subnet B
#################
resource "aws_subnet" "private_B" {
  count             = length(data.aws_availability_zones.available.names)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets_B[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.name}_private_subnets_B"
  }
}



# creating  NAT Gateway  EIP


resource "aws_eip" "nat" {
  count = length(data.aws_availability_zones.available.names)
  vpc   = true

  tags = {
    Name = "${var.name}_EIP_nat"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  count         = length(data.aws_availability_zones.available.names)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.name}_EIP_nat_gateway"
  }
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_route" "private_A_nat_gateway" {
  count                  = length(data.aws_availability_zones.available.names)
  route_table_id         = aws_route_table.private_A[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw[count.index].id

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "private_B_nat_gateway" {
  count                  = length(data.aws_availability_zones.available.names)
  route_table_id         = aws_route_table.private_B[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw[count.index].id

  timeouts {
    create = "5m"
  }
}


# Route table association 

resource "aws_route_table_association" "private_A" {
  count          = length(data.aws_availability_zones.available.names)
  subnet_id      = aws_subnet.private_A[count.index].id
  route_table_id = aws_route_table.private_A[count.index].id
}

resource "aws_route_table_association" "private_B" {
  count          = length(data.aws_availability_zones.available.names)
  subnet_id      = aws_subnet.private_B[count.index].id
  route_table_id = aws_route_table.private_B[count.index].id
}

resource "aws_route_table_association" "public" {
  count          = length(data.aws_availability_zones.available.names)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

#####   SG

resource "aws_security_group" "publicSG" {
   name        = "allow_web_traffic"
   description = "Allow Web inbound traffic"
   vpc_id      = aws_vpc.main.id

   ingress {
     description = "HTTPS"
     from_port   = 443
     to_port     = 443
     protocol    = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
   }
   ingress {
     description = "HTTP"
     from_port   = 80
     to_port     = 80
     protocol    = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
   }
   ingress {
     description = "SSH"
     from_port   = 22
     to_port     = 22
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
    Name = "${var.name}_allow_from_WEB"
  }

}
 
resource "aws_security_group" "privateSG" {
   name        = "allow_lb_traffic"
   description = "Allow LB traffic to asg group"
   vpc_id      = aws_vpc.main.id

   ingress {
     description = "HTTPS"
     from_port   = 443
     to_port     = 443
     protocol    = "tcp"
     security_groups = [aws_security_group.publicSG.id]
   }
   
   ingress {
     description = "HTTP"
     from_port   = 80
     to_port     = 80
     protocol    = "tcp"
     security_groups = [aws_security_group.publicSG.id]
   }

   ingress {
     description = "SSH"
     from_port   = 22
     to_port     = 22
     protocol    = "tcp"
     security_groups = [aws_security_group.publicSG.id]
  }

  egress {
     from_port   = 0
     to_port     = 0
     protocol    = "-1"
     cidr_blocks = ["0.0.0.0/0"]
   }

   tags = {
    Name = "${var.name}_allow_from_public_sg"
  }
  depends_on = [aws_security_group.publicSG]
}
 
#####  INSTANCE LAUNCH TEMPLATE

resource "aws_launch_template" "launch_template" {
  name                                 = "${var.name}_asg_template"
  #ebs_optimized                        = true
  image_id                             = data.aws_ami.ubuntu.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = var.instance_type
  key_name                             = var.key_name
  network_interfaces {
    associate_public_ip_address = false
    subnet_id                   = aws_subnet.private_A[count.index].id
    security_groups             = aws_security_group.privateSG.id
    delete_on_termination       = true
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 10
      volume_type ="gp2"
    }
  }
  
  block_device_mappings {
    device_name = "/dev/xvdb"
    ebs {
      volume_size = 10
      volume_type ="gp2"
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name          = "${var.name}_asg_template"
    }
  }
  user_data = filebase64("user_data.sh")

  # we don't want to create a new template just because there is a newer AMI
  lifecycle {
    ignore_changes = [
      image_id,
    ]
  }
}



#### Auto Scaling Group


resource "aws_autoscaling_group" "demo_asg" {
  availability_zones   = ["${data.aws_availability_zones.all.names}"]
  desired_capacity     = 4
  min_size = 2
  max_size = 6
  launch_template = {
      id      = "${aws_launch_template.launch_template.id}"
      version = "$$Latest"
    }
  load_balancers       = ["${aws_lb.test.name}"]
  health_check_type    = "ELB"
  
  tag {
    key   = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }

   depends_on = [aws_launch_template.launch_template]
}



###  ELB  ALB
resource "aws_lb" "test" {
  name               = "${var.name}_test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.publicSG.id]
  subnets            = [aws_subnet.public.*.id]
  cross_zone_load_balancing  = true
  enable_deletion_protection = true

health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:80"
  }
  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "80"
    instance_protocol = "http"
  }
}
  

  tags = {
    Environment = "${var.name}_demo"
  }
}
