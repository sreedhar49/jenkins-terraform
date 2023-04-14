variable "awsprops" {
    type = map
    default = {
    region = "eu-west-2"
    vpc = "vpc-0681ae9ff3b106241"
    ami = "ami-0cd8ad123effa531a"
    itype = "t2.micro"
    subnet = "subnet-08f0875eaeaaacd70"
    publicip = true
    keyname = "sridhar-keypair"
    secgroupname = "Terraform-linux-sgrp"
   # associate_public_ip_address = true
   }
  }


provider "aws" {
  region = lookup(var.awsprops, "region")
}

/*resource "aws_instance" "web" {
 #userdata
    user_data = <<EOF
    #!/bin/bash
    sudo yum update –y
    #sudo yum install -y httpd
    #sudo service httpd start
    #sudo chkconfig httpd on
    #sudo groupadd www
    #sudo usermod -a -G www ec2-user
    #sudo chown ec2-user /var/www/html/ -R
    #sudo echo "Auto-Scaling of webserver" > /var/www/html/index.html
    sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
    sudo yum upgrade
    sudo amazon-linux-extras install java-openjdk11 -y
    sudo yum install jenkins -y
    sudo systemctl enable jenkins
    sudo systemctl start jenkins
    EOF
    tags = {
      Name = "Cloudtraining"
  }
}*/

resource "aws_security_group" "terraformsgrp" {
  name = lookup(var.awsprops, "secgroupname")
  description = lookup(var.awsprops, "secgroupname")
  vpc_id = lookup(var.awsprops, "vpc")

  // To Allow SSH Transport
  ingress {
     from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // To Allow Port 80 Transport
  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

   ingress {
    from_port = 8080
    protocol = "tcp"
    to_port = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_instance" "project-iac" {
  ami = lookup(var.awsprops, "ami")
  instance_type = lookup(var.awsprops, "itype")
  subnet_id = lookup(var.awsprops, "subnet") #FFXsubnet2
  associate_public_ip_address = lookup(var.awsprops, "publicip")
  key_name = lookup(var.awsprops, "keyname")


  vpc_security_group_ids = [
    aws_security_group.terraformsgrp.id
  ]
  root_block_device {
    delete_on_termination = true
    #iops = 150
    volume_size = 8
    volume_type = "gp2"
  }
  tags = {
    Name ="SERVER01"
    Environment = "DEV"
    OS = "Amazon Linux 2"
    Managed = "IAC"
  }
  user_data = "${file("ec2-user-data.sh")}"
  depends_on = [ aws_security_group.terraformsgrp ]
}

output "ec2instance" {
  value = aws_instance.project-iac.public_ip
}

