provider "aws" {
  region = "eu-central-1"
}

# Fetch the AMI ID from the .bin file in S3
data "aws_s3_object" "ami_bin_file" {
  bucket = "testec2ami"  # Replace with your S3 bucket name
  key    = "ami-0dd88b73d06f3d468.bin"  # Replace with your S3 object key
}

/*# Fetch the AMI ID stored in S3 as a .bin file
data "aws_s3_object" "ami_bin_file" {
  bucket = "testec2ami"  # Replace with your S3 bucket name
  key    = "ami-0dd88b73d06f3d468.bin"  # Replace with your S3 object key
}

# Read the contents of the .bin file to get the AMI ID
data "local_file" "ami_id" {
  content  = data.aws_s3_object.ami_bin_file.body
  filename = "${path.module}/ami_id.txt"
}*/

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-central-1a"
  map_public_ip_on_launch = true
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group allowing SSH access
resource "aws_security_group" "allow_ssh" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance using AMI stored in S3
resource "aws_instance" "web" {
  ami                         = "ami-0dd88b73d06f3d468"  # Replace with your AMI ID manually
  #ami                         = trimspace(file("${path.module}/ami_id.txt"))
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id]


  tags = {
    Name = "web-instance"
  }
}

output "instance_public_ip" {
  value = aws_instance.web.public_ip
}

