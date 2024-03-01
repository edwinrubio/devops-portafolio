terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "my-bucket-terraform2135"
    key            = "terraform/Escalable-vpc-achitecture"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lockid"
  }
}

# Configure the AWS Provider
provider "aws" {
  region     = "us-east-1"
  access_key = var.access_key
  secret_key = var.secret_key
}


resource "aws_launch_configuration" "launch-config" {
  name            = "launch-config"
  image_id        = "ami-0e731c8a588258d0d"
  instance_type   = "t2.micro"
  user_data       = <<-EOF
  #!/bin/bash

  # Actualizar el índice de paquetes
  sudo yum update -y

  # Instalar Apache
  sudo yum install httpd -y

  # Instalar git 
  sudo yum install git -y

  # Iniciar el servicio de Apache
  sudo systemctl start httpd

  # Habilitar Apache para que se inicie en el arranque del sistema
  sudo systemctl enable httpd

  #Descargar el codigo desde
  sudo git clone https://bitbucket.org/dptrealtime/html-web-app.git /var/www/html

  # Mostrar el estado del servicio de Apache
  sudo systemctl status httpd
  EOF
  security_groups = [aws_security_group.app_security_group.id]
}


resource "aws_autoscaling_group" "my-autoescaling-group" {
  desired_capacity     = 1
  max_size             = 2
  min_size             = 1
  launch_configuration = aws_launch_configuration.launch-config.name
  health_check_type    = "EC2"
  vpc_zone_identifier  = module.vpc-app.private_subnets
  target_group_arns    = [aws_lb_target_group.target-group-app.arn]

    enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

}

resource "aws_lb_target_group" "target-group-app" {
  name     = "target-group-app"
  port     = 80
  protocol = "TCP"
  vpc_id   = module.vpc-app.vpc_id

}


resource "aws_autoscaling_policy" "autoescaling-policy-app" {
  name                   = "example-autoscaling-policy"
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.my-autoescaling-group.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {

    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"  # Utilización promedio de CPU del grupo de autoescalado
    }
    target_value = 50
  }
}



//Load balancer configuration

resource "aws_lb" "my-lb-app" {
  name               = "my-lb"
  internal           = false
  load_balancer_type = "network"
  security_groups    = [aws_security_group.app_security_group.id]
  subnets            = module.vpc-app.public_subnets


}

resource "aws_lb_listener" "listener-lb-app" {
  load_balancer_arn = aws_lb.my-lb-app.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target-group-app.arn
  }
}


//Bastion of the infraestructure

resource "aws_instance" "bastion" {
  ami           = "ami-0e731c8a588258d0d"  # AMI de Amazon Linux 2
  instance_type = "t2.micro"               # Tipo de instancia
  key_name      = aws_key_pair.mi_clave_ssh.key_name         # Nombre de la clave SSH
  subnet_id     = module.vpc-bastion.public_subnets[0] # ID de la subred pública donde se ubicará el bastión

  # Configura las reglas de seguridad para permitir el acceso SSH desde tu dirección IP
  security_groups = [aws_security_group.bastion_security_group.id]
}

resource "aws_key_pair" "mi_clave_ssh" {
  key_name   = "mi_clave_ssh"
  public_key = file("~/.ssh/id_rsa.pub")  # Ruta de tu clave pública SSH local
}






