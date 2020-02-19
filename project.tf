provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

data "aws_vpc" "default" {}

resource "aws_key_pair" "auth" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

resource "aws_instance" "jenkins" {
  ami                     = var.centos_ami
  instance_type           = "t2.small"
  disable_api_termination = true

  tags = {
    Name = "Jenkins"
  }

  vpc_security_group_ids = ["${aws_security_group.employee.id}"]
  key_name               = aws_key_pair.auth.id
}

resource "aws_instance" "jump" {
  ami                         = var.centos_ami
  instance_type               = "t2.micro"
  associate_public_ip_address = true

  tags = {
    Name = "Jump"
  }

  vpc_security_group_ids = ["${aws_security_group.jump.id}"]
  key_name               = aws_key_pair.auth.id

  connection {
    type        = "ssh"
    user        = "ec2-user"
    host        = coalesce(self.public_ip, self.private_ip)
    private_key = file(var.private_key_path)
  }

  provisioner "file" {
    source      = "~/.ssh/id_rsa"
    destination = "~/.ssh/id_rsa"
  }


  provisioner "file" {
    source      = "~/.ssh/id_rsa.pub"
    destination = "~/.ssh/authorized_keys"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod 400 ~/.ssh/id_rsa",
      "sudo chmod 600 ~/.ssh/authorized_keys"
    ]
  }
}

resource "aws_instance" "prod" {
  ami           = var.centos_ami
  instance_type = "t2.micro"

  tags = {
    Name = "Prod"
  }

  vpc_security_group_ids = ["${aws_security_group.employee.id}"]
  key_name               = aws_key_pair.auth.id
}

resource "aws_instance" "dev" {
  ami           = var.centos_ami
  instance_type = "t2.micro"

  tags = {
    Name = "Dev"
  }

  vpc_security_group_ids = ["${aws_security_group.employee.id}"]
  key_name               = aws_key_pair.auth.id
}

resource "aws_eip" "jump_ip" {
  instance = aws_instance.jump.id
  vpc      = true
}

resource "aws_eip" "jenkins_ip" {
  instance = aws_instance.jenkins.id
  vpc      = true
}

resource "aws_eip" "prod_ip" {
  instance = aws_instance.prod.id
  vpc      = true
}

resource "aws_eip" "dev_ip" {
  vpc = true
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.dev.id
  allocation_id = aws_eip.dev_ip.id
}


resource "aws_security_group" "customer" {
  name        = "Customer"
  description = "Allows customers access to the resources created in the cloud."
  vpc_id      = data.aws_vpc.default.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "jump" {
  name        = "Jump"
  description = "Allows the employee access to the jump machine."
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32", data.aws_vpc.default.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "employee" {
  name        = "Employee"
  description = "Allows employees access to the resources created in the cloud."
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["${aws_instance.jump.public_ip}/32", data.aws_vpc.default.cidr_block]
    security_groups = [aws_security_group.jump.id]
  }

  lifecycle {
    ignore_changes = [ingress]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "allow_jump" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["${aws_instance.jenkins.public_ip}/32"]

  security_group_id = aws_security_group.employee.id
}

resource "local_file" "ansible_resource" {
  content = <<EOF

Host 172.31.*
  ProxyCommand ssh -W %h:%p ec2-user@${aws_instance.jump.public_ip}
  IdentityFile ~/.ssh/id_rsa

Host ${aws_instance.jump.public_ip}
  User ec2-user 
  ControlMaster auto
  ControlPath ./ansible/ansible-%%r@%h:%p
  ControlPersist 15m
  IdentityFile ~/.ssh/id_rsa
EOF

  filename = "/home/asafi/.ssh/ssh.cfg"

}

resource "local_file" "ansible_inventory" {
  content = <<EOF
[bastion]
${aws_instance.jump.public_ip}

[jenkins]
${aws_instance.jenkins.private_ip}

[httpd]
${aws_instance.dev.private_ip}
${aws_instance.prod.private_ip}
EOF

  filename = "aws_hosts"

}

resource "null_resource" "deploy_httpd" {

  depends_on = [aws_instance.jump, aws_instance.jenkins, aws_instance.dev, aws_instance.prod]

  provisioner "local-exec" {
    command = "aws ec2 wait instance-status-ok --instance-ids ${aws_instance.dev.id} --profile default && ansible-playbook -i aws_hosts apache.yml"
  }
}

resource "null_resource" "deploy_jenkins" {

  depends_on = [aws_instance.jump, aws_instance.jenkins, aws_instance.dev, aws_instance.prod]

  provisioner "local-exec" {
    command = "aws ec2 wait instance-status-ok --instance-ids ${aws_instance.jenkins.id} --profile default && ansible-playbook -i aws_hosts jenkins.yml"
  }
}
