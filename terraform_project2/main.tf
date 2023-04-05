# Configure the AWS Provider
provider "aws" {
  region  = "us-east-1"
}

# Configure EC2 
resource "aws_instance" "srvr" {
  ami           = "ami-0aa2b7722dc1b5612"
  instance_type = "t2.micro"

  tags = {
    Name = "ubuntu"
  }
}

# Configure VPC 
resource "aws_vpc" "first-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "production"
  }
}

resource "aws_vpc" "second-vpc" {
  cidr_block = "10.1.0.0/16"

  tags = {
    Name = "Dev"
  }
}

# Configure subnets 
resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.first-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "prod-subnet"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id     = aws_vpc.second-vpc.id
  cidr_block = "10.1.1.0/24"

  tags = {
    Name = "dev-subnet"
  }
}