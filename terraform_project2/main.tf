# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Configure EC2 
# resource "aws_instance" "srvr" {
#   ami           = "ami-0aa2b7722dc1b5612"
#   instance_type = "t2.micro"

#   tags = {
#     Name = "ubuntu"
#   }
# }

# Configure VPC 
# resource "aws_vpc" "first-vpc" {
#   cidr_block = "10.0.0.0/16"

#   tags = {
#     Name = "production"
#   }
# }

# resource "aws_vpc" "second-vpc" {
#   cidr_block = "10.1.0.0/16"

#   tags = {
#     Name = "Dev"
#   }
# }

# Configure subnets 
# resource "aws_subnet" "subnet1" {
#   vpc_id     = aws_vpc.first-vpc.id
#   cidr_block = "10.0.1.0/24"

#   tags = {
#     Name = "prod-subnet"
#   }
# }

# resource "aws_subnet" "subnet2" {
#   vpc_id     = aws_vpc.second-vpc.id
#   cidr_block = "10.1.1.0/24"

#   tags = {
#     Name = "dev-subnet"
#   }
# }


# # 0. Variables 
variable "main_subnet" {
  # type = string
}

variable "subnet_prefix" {
  description = "cidr block for the subnet"
  # default     = "10.0.1.0/24"
  # type        = string
}



# # 1. Create vpc
resource "aws_vpc" "prod-vpc" {
  # cidr_block = "10.0.0.0/16" 
  cidr_block = var.main_subnet[0].subnet

  tags = {
    Name = var.main_subnet[0].name
  }
}

# # 2. Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id

  tags = {
    Name = "gw"
  }
}

# # 3. Create Custom Route Table
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "prod"
  }
}

# # 4. Create a Subnet 
resource "aws_subnet" "subnet-1" {
  vpc_id            = aws_vpc.prod-vpc.id
  # cidr_block        = "10.0.1.0/24"
  cidr_block = var.subnet_prefix[0].cidr_block
  availability_zone = "us-east-1a"

  tags = {
    Name = var.subnet_prefix[0].name
  }
}

resource "aws_subnet" "subnet-2" {
  vpc_id            = aws_vpc.prod-vpc.id
  # cidr_block        = "10.0.1.0/24"
  cidr_block = var.subnet_prefix[1].cidr_block
  availability_zone = "us-east-1a"

  tags = {
    Name = var.subnet_prefix[1].name
  }
}

# # 5. Associate subnet with Route Table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}

# # 6. Create Security Group to allow port 22,80,443
resource "aws_security_group" "allow-web" {
  name        = "allow-web-traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description = "HTTPS Traffic"
    # Allow ports range from 443 to 447 
    # from_port        = 443
    # to_port          = 447
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Any ip can access it via this port 
  }

  ingress {
    description = "HTTP Traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH Traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    # Allow all ports in the egress direction: 
    from_port = 0
    to_port   = 0
    # Any Protocol:  
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

# # 7. Create a network interface with an ip in the subnet that was created in step 4
resource "aws_network_interface" "web-server-nic" {
  subnet_id = aws_subnet.subnet-1.id
  # Any ip from range subnet: 
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow-web.id]

}

# # 8. Assign an elastic IP to the network interface created in step 7
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  # EIP may require IGW to exist prior to association. Use depends_on to set an explicit dependency on the IGW.
  # depends_on = [aws_internet_gateway.gw]
}

# Print Public ip 
output "server_public_ip" {
  value = aws_eip.one.public_ip
}

# # 9. Create Ubuntu server and install/enable apache2
resource "aws_instance" "srvr" {
  ami               = "ami-0aa2b7722dc1b5612"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  key_name          = "DT"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }

  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo Hello, Terraform. > /var/www/html/index.html'
                EOF

  tags = {
    Name = "web-server"
  }
}
# Print Private ip
output "server_private_ip" { 
  value = aws_instance.srvr.private_ip
}
# Print srvr state 
output "server_state" {
  value = aws_instance.srvr.instance_state
}